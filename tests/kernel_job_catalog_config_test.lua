local J = dofile('tests/kernel_job_catalog_harness.lua')
local H, count = J.H, 0
local cases = {
    {}, {seed = {custom = {keep = true}, Payments = {obsolete = 5}}},
    {command = 'custom', adminAce = 'custom.ace'}, {command = false, adminAce = false},
    {convars = {['forge:paycheck:enabled'] = 'false', ['pinel:paycheck:enabled'] = 'true'}},
    {convars = {['pinel:paycheck:interval'] = '30', ['pinel:mei:openingCost'] = '7000'}},
    {convars = {['forge:paycheck:interval'] = '', ['pinel:paycheck:interval'] = '40'}},
    {convars = {['forge:paycheck:societyPercent'] = 'not-a-number', ['forge:mei:monthlyCost'] = '-2'}},
    {convars = {['forge:paycheck:account'] = '', ['forge:mei:governmentAccount'] = 'treasury'}},
    {convars = {['forge:paycheck:payOffDuty'] = 'TRUE', ['forge:paycheck:society'] = 'true'}},
    {convars = {['forge:mei:enabled'] = '1', ['forge:paycheck:notify'] = 'false'}},
    {convars = {['forge:paycheck:interval'] = '2.5', ['forge:mei:paymentAccount'] = 'cash'}},
}
for _, options in ipairs(cases) do
    local a, b = J.config(false, options), J.config(true, options)
    H.same(b.config, a.config, 'full shared job config')
    H.same(b.trace, a.trace, 'convar/translation order')
    assert(a.config == a.seed and b.config == b.seed, 'preserve pre-existing Job table identity')
    count = count + 1
end
local config = J.config(true).config
assert(config.Storage.jobsFile == 'data/jobs.json' and config.Storage.gangsFile == 'data/gangs.json')
assert(config.Protected.jobs.unemployed and config.Protected.gangs.none)
assert(config.Payments.intervalMinutes == 10 and config.Mei.openingCost == 5000)
assert(config.Callbacks.fireEmployee and config.Callbacks.toggleDuty and config.Points.defaultSlots == 50)
print(('PASS job catalog config: %d differential cases, full installed fields/defaults and explicit read-only ports'):format(count))
