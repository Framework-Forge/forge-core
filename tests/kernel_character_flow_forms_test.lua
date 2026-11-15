local F=dofile('tests/kernel_character_flow_harness.lua')
local H=F.H
local count=0
local function check(name,fn,config) count=count+1;return F.compare(name,fn,config) end
check('external character manager disables complete flow',function(r)
    assert(#r.events==0 and #r.threads==0 and #r.trace==0)
end,function(r) r.config.characters.useExternalCharacters=true end)
for _,limited in ipairs({true,false}) do
    for _,settings in ipairs({false,{},'invalid',{firstNamePlaceholder='Ana',lastNamePlaceholder='Silva',
        birthdateMax='2000-03-15',termsEnabled=true,termsTitle='Terms',termsText='Text'},
        {termsEnabled=true},{termsEnabled=false,birthdateMax='1990-12-31'}}) do
        check('dialog '..tostring(limited)..' '..count,function(r)
            r.fillNationalities();return r.api.characterDialog(H.copy(settings))
        end,function(r) r.config.characters.limitNationalities=limited end)
    end
end
check('dialog before nationality thread runs',function(r)
    r.api.characterDialog()
    assert(#r.lastDialog[2][3].options==0)
end)
check('nationalities preserve order and duplicates',function(r)
    r.fillNationalities();r.api.characterDialog()
    local values=r.lastDialog[2][3].options
    assert(#values==4 and values[2].value=='Brazilian' and values[3].value==values[4].value)
end)
for _,value in ipairs({'bad','BAD','bad word','a bad b','a b c d e','a b c d e f',
    'Good','Good Word',"O'BRIEN",'a  b','bad!','', 'bád','American'}) do
    check('name validation '..value,function(r) return r.api.checkStrings({value},1) end)
end
check('nil registration field retains error',function(r) return r.api.checkStrings({},1) end)
check('numeric registration field retains error',function(r) return r.api.checkStrings({5},1) end)
for _,value in ipairs({'hANK jORDAN',"o'BRIEN",'HELLO-WORLD','Álvaro DA SILVA','a b c','',
    '12345','two  spaces','bad word'}) do
    check('capitalization '..value,function(r) return r.api.capString(value) end)
end
for _,configured in ipairs({true,false}) do
    check('cancel registration '..tostring(configured),function(r)
        assert(r.api.createCharacter(1,{termsEnabled=true})==false)
    end,function(r) r.previewConfigured=configured;r.dialogs={false} end)
end
local valid={'hANK','jORDAN','bRAZILIAN','info.char_male','1990-01-01',true}
for _,code in ipairs({'character_slot_unavailable','character_slot_locked','character_slot_occupied',
    'character_terms_required','minimum_age_required','invalid_birthdate','unknown'}) do
    check('create refusal '..code,function(r) return r.api.createCharacter(2,{}) end,
        function(r) r.dialogs={H.copy(valid)};r.createError=code end)
end
for _,acceptance in ipairs({false,{false,false},{'Text',false},{'Text',true}}) do
    check('separate terms consent '..count,function(r)
        return r.api.createCharacter(1,{termsEnabled=true,termsTitle='Title',termsText='Rules'})
    end,function(r) r.dialogs={H.copy(valid),H.copy(acceptance)};r.createError='character_terms_required' end)
end
check('termsAccepted comes from first checkbox even after second confirmation',function(r)
    r.api.createCharacter(1,{termsEnabled=true})
    for _,e in ipairs(r.trace) do
        if e.kind=='callback' and e.args[1]=='qbx_core:server:createCharacter' then
            assert(e.args[3].termsAccepted==false and e.args[3].cid==1)
        end
    end
end,function(r)
    local value=H.copy(valid);value[6]=false
    r.dialogs={value,{'text',true}};r.createError='character_terms_required'
end)
check('blacklist retries before server create',function(r)
    r.api.createCharacter(1)
    assert(r.dialogIndex==2)
    local calls=0
    for _,e in ipairs(r.trace) do if e.kind=='callback' then calls=calls+1 end end
    assert(calls==1)
end,function(r)
    local bad=H.copy(valid);bad[2]='BAD'
    r.dialogs={bad,H.copy(valid)}
end)
check('too many words retries then cancellation',function(r)
    return r.api.createCharacter(1)
end,function(r)
    local bad=H.copy(valid);bad[3]='a b c d e f';r.dialogs={bad,false}
end)
check('normalized payload and unexpected gender retained',function(r)
    r.api.createCharacter(4,{})
    for _,e in ipairs(r.trace) do if e.kind=='callback' then
        local value=e.args[3]
        assert(value.firstname=='Hank' and value.lastname=='Jordan' and value.nationality=='Brazilian')
        assert(value.gender==1 and value.termsAccepted==true and value.cid==4)
    end end
end,function(r)
    local value=H.copy(valid);value[4]='unexpected';r.dialogs={value}
end)
check('missing input field retains error before callback',function(r)
    return r.api.createCharacter(1,{})
end,function(r) r.dialogs={{'Name'}} end)
check('nil callback error maps to general refusal',function(r)
    return r.api.createCharacter(1,{})
end,function(r) r.dialogs={H.copy(valid)} end)
print('PASS character flow forms: '..count..' differential cases; complete dialogs/nationalities/terms, validation/multiple returns, cancellation/retries and exact create payload/refusals; no UI or DB')
