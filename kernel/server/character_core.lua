-- Private attachment to the existing PlayerCore and the very same slot policy.
-- Bootstrap must inject slots.Service into Player ports before constructing that PlayerCore.
local createCharacter = require 'kernel.server.character'
local createDocuments = require 'kernel.server.document_items'

return function(base, playerCore, ports)
    assert(type(base) == 'table' and base.PlayerCore == playerCore, 'existing player core required')
    assert(type(playerCore) == 'table' and playerCore.Characters == nil, 'fresh character attachment required')
    assert(type(ports) == 'table' and type(ports.slots) == 'table', 'canonical slot module required')
    local slots = assert(ports.slots.Service, 'stable slot policy required')
    assert(ports.slotPolicy == slots, 'Player slot policy identity must be explicit')
    local functions = assert(playerCore.Lifecycle, 'existing lifecycle required').Functions
    local players = assert(playerCore.Players, 'internal Player service required')
    local documents = createDocuments(assert(ports.documents, 'PR document ports required'))
    local character = createCharacter({config = ports.config, logger = ports.logger, storage = playerCore.Storage,
        starterItems = ports.starterItems, documentItems = documents, slots = slots, inventory = ports.inventory,
        native = ports.native, library = ports.library, previewsReady = ports.previewsReady,
        getPreviews = ports.getPreviews, login = players.Login,
        -- The similarly named public DeleteCharacter export is force-delete; never use it here.
        deleteCharacter = assert(players.Callbacks['qbx_core:server:deleteCharacter'], 'ownership checked delete callback required'),
        notify = assert(functions.Notify, 'internal Notify required'), locale = ports.locale})
    local api = {State = playerCore.State, Slots = ports.slots, Documents = documents, Character = character}
    playerCore.Characters = api
    return api
end
