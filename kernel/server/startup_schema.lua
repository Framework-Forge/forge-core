-- Only the two installed users/userId bootstrap statements. Not a general SQL cache/migrator.
return function(ports)
    local current,execute,inspect=assert(ports.isCurrent),assert(ports.execute),assert(ports.inspect)
    local phase,index,verified='prepared',0,false
    local records={};local api={OperationalReady=false,Rollback=false}
    local function valid()assert(phase~='closed'and phase~='failed'and current(),'schema context revoked')end
    local function matches(id,sql)
        if type(sql)~='string'then return false end
        local compact=sql:gsub('%s+',' ')
        if id=='users'then return compact:find('CREATE TABLE IF NOT EXISTS `users` (',1,true)~=nil end
        if id=='playerUserId'then return compact:find('ALTER TABLE `players` ADD COLUMN IF NOT EXISTS `userId` INT UNSIGNED DEFAULT NULL AFTER `id`;',1,true)~=nil end
        return false
    end
    api.Matches=matches
    function api.Execute(id,sql,...)
        valid();assert(matches(id,sql),'unexpected bootstrap schema statement')
        local args=table.pack(...);assert(args.n==0,'installed bootstrap schema has no extra parameters')
        local prior=records[id]
        if prior then
            assert(phase=='ready'and prior.sql==sql and prior.result,'schema replay is not an exact completed operation')
            return table.unpack(prior.result,1,prior.result.n)
        end
        assert(phase=='preparing','schema can execute only during explicit Prepare')
        assert(id==(index==0 and'users'or index==1 and'playerUserId'or nil),'bootstrap schema order changed')
        local record={sql=sql,status='entered'};records[id]=record
        local result=table.pack(pcall(execute,sql));valid()
        if not result[1]then record.status='failed';error(result[2],0)end
        assert(result[2]~=false,'schema executor refused')
        local values={n=result.n-1};for i=2,result.n do values[i-1]=result[i]end
        record.result,record.status=values,'completed';index=index+1
        return table.unpack(values,1,values.n)
    end
    function api.Prepare(handler)
        if phase~='prepared'then return false,'schema_preparation_not_repeatable'end
        phase='preparing'
        local ok,err=pcall(function()
            valid();handler();valid();assert(index==2,'both bootstrap schema statements required')
            phase='verifying';local ready=inspect();valid();assert(ready==true,'bootstrap schema inspection failed')
            verified=true;phase='ready'
        end)
        if not ok then if phase~='closed'then phase='failed'end;return false,err end
        return true
    end
    function api.Close()phase='closed';return true end
    function api.Progress()
        local out={phase=phase,completed=index,verified=verified,statements={}}
        for _,id in ipairs({'users','playerUserId'})do out.statements[id]=records[id]and records[id].status or'pending'end
        return out
    end
    return api
end
