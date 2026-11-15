local R=dofile('tests/kernel_character_renderer_harness.lua')
local H=R.H
local count=0
local function check(label,action,config) count=count+1;return R.compare(label,action,config) end
for _,distance in ipairs({false,-8,0,0.5,1,3.2,10,11,'2.5','invalid'}) do
    for _,heading in ipairs({0,90,180,270}) do
        check('distance '..tostring(distance)..' heading '..heading,function(r)
            r.config.characters.previewCameraDistance=distance
            local point=r.api.previewCameraPosition({x=10,y=20,z=30,heading=heading})
            local expected=math.max(1,math.min(tonumber(distance) or 3.2,10))
            assert(math.abs((point.x-10)^2+(point.y-20)^2-expected^2)<0.000001)
            assert(point.z==31.65)
            return point
        end)
    end
end
for _,location in ipairs({{x=1,y=2,z=3,w='45'},{x=1,y=2,z=3,heading='bad'},
    {x=1,y=2,z=3,ped=10,heading=0},{x=1,y=2,z=3,ped=999,heading=0}}) do
    check('target '..count,function(r)
        return r.api.previewCameraTargetPosition(location),r.api.previewCameraPosition(location)
    end)
end
check('fallback setup/dof and cleanup',function(r)
    r.api.setupPreviewCam()
    r.step(1);r.step(1)
    r.api.destroyPreviewCam()
    r.run(1)
    assert(next(r.cameras)==nil and r.entities[10])
end)
check('configured setup no shallow dof',function(r)
    r.api.buildConfiguredPreviews({},1,{{x=5,y=6,z=7,heading=90}})
    r.api.setupPreviewCam(r.api.configuredOverview())
    r.step(1);r.api.destroyPreviewCam();r.run(1)
    for _,e in ipairs(r.trace) do assert(e.kind~='SetUseHiDof') end
end)
check('no camera transition guards',function(r)
    assert(not r.api.transitionPreviewCamera(nil))
    assert(not r.api.transitionPreviewCamera({x=0,y=0,z=0}))
    assert(not r.api.focusConfiguredPreview(1))
    assert(not r.api.showConfiguredOverview())
end)
check('900ms smoothstep every frame',function(r)
    r.api.setupPreviewCam({x=0,y=0,z=0,heading=0})
    local target={x=100,y=200,z=20,heading=90}
    assert(r.api.transitionPreviewCamera(target))
    r.run(2)
    local endPoint=r.api.previewCameraPosition(target)
    H.same(r.cameras[501].coords,endPoint)
    local frames={}
    for _,e in ipairs(r.trace) do if e.kind=='SetCamCoord' then frames[#frames+1]=e.args end end
    assert(#frames==10 and r.now==900)
    local blend=(1/9)^2*(3-2/9)
    assert(math.abs(frames[2][2]-(100-3.2)*blend)<0.000001)
    r.api.destroyPreviewCam();r.run(1)
end)
check('new focus cancels old movement',function(r)
    r.api.buildConfiguredPreviews({},2,{{x=0,y=0,z=0,heading=0},{x=100,y=50,z=10,heading=90}})
    r.api.setupPreviewCam(r.api.configuredOverview())
    assert(r.api.focusConfiguredPreview(2));r.step(2)
    assert(r.api.focusConfiguredPreview(1))
    r.run(2);r.run(3)
    H.same(r.cameras[501].coords,r.api.previewCameraPosition(r.api.configuredOverview()))
    r.api.destroyPreviewCam();r.run(1)
end)
check('destroy cancels movement before next frame',function(r)
    r.api.setupPreviewCam({x=0,y=0,z=0,heading=0})
    r.api.transitionPreviewCamera({x=10,y=0,z=0,heading=0});r.step(2)
    r.api.destroyPreviewCam();local traceSize=#r.trace
    r.run(2);r.run(1)
    assert(#r.trace==traceSize and next(r.cameras)==nil)
end)
check('new camera identity cancels old movement',function(r)
    r.api.setupPreviewCam({x=0,y=0,z=0,heading=0})
    r.api.transitionPreviewCamera({x=10,y=0,z=0,heading=0});r.step(2)
    r.api.setupPreviewCam({x=90,y=0,z=0,heading=0})
    r.run(2);r.api.destroyPreviewCam();r.run(3)
    -- Installed setup does not destroy the previous camera on repeated setup.
    assert(r.cameras[501] and not r.cameras[502])
    r.native.DestroyCam(501,true);r.run(1)
end)
check('externally missing camera',function(r)
    r.api.setupPreviewCam({x=0,y=0,z=0,heading=0});r.cameras[501]=nil
    assert(not r.api.transitionPreviewCamera({x=1,y=0,z=0,heading=0}))
    r.run(1);r.api.destroyPreviewCam()
end)
check('focus invalid slot does not start a movement',function(r)
    r.api.buildConfiguredPreviews({},1,{{x=0,y=0,z=0,heading=0}})
    r.api.setupPreviewCam(r.api.configuredOverview())
    assert(not r.api.focusConfiguredPreview(2) and #r.threads==1)
    r.api.destroyPreviewCam();r.run(1)
end)
check('overview back focus',function(r)
    r.api.buildConfiguredPreviews({[2]={citizenid='A'}},2,
        {{x=0,y=0,z=0,heading=0},{x=30,y=40,z=0,heading=0}})
    r.api.setupPreviewCam(r.api.configuredOverview())
    assert(r.api.focusConfiguredPreview(1));r.run(2)
    assert(r.api.showConfiguredOverview());r.run(3)
    H.same(r.cameras[501].coords,r.api.previewCameraPosition(r.api.configuredOverview()))
    r.api.destroyPreviewCam();r.run(1)
end)
check('empty cleanup without camera is repeatable',function(r)
    r.api.destroyPreviewCam();r.api.destroyPreviewCam()
end)
check('inherited setup does not unfreeze hidden player until destroy',function(r)
    r.api.buildConfiguredPreviews({},1,{{x=0,y=0,z=0,heading=0}})
    r.api.setupPreviewCam(r.api.configuredOverview())
    r.api.destroyPreviewCam();r.run(1)
    local lastFreeze
    for _,e in ipairs(r.trace) do if e.kind=='FreezeEntityPosition' and e.args[1]==10 then lastFreeze=e.args[2] end end
    assert(lastFreeze==false)
end)
print('PASS character renderer camera: '..count..' differential cases; clamp/head targets/DOF, 900ms frames, revision/camera cancellation, cleanup and retained repeated-setup leak; simulated scheduler only')
