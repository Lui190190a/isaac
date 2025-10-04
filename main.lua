local mod = RegisterMod("The Purgatory Package", 1)
local game = Game()

local DEVILS_COIN_ID = nil

-- Corrigido cálculo de chance baseado em sorte negativa
function mod:CalculateSuccessChance(player)
    local luck = player.Luck
    local baseFailChance = 66
    
    -- Sorte negativa REDUZ a chance de falha
    if luck < 0 then
        baseFailChance = baseFailChance + (luck * 5)
    end
    
    -- Mínimo de 10% de falha
    baseFailChance = math.max(10, baseFailChance)
    return 100 - baseFailChance
end

-- Reescrito para usar Isaac.GetRoomEntities() ao invés de FindInRadius
function mod:OnUseDevilsCoin(itemID, rng, player, useFlags, slot, customVarData)
    if not DEVILS_COIN_ID or itemID ~= DEVILS_COIN_ID then
        return
    end
    
    Isaac.DebugString("[Devil's Coin] Item usado!")
    
    local successChance = mod:CalculateSuccessChance(player)
    local roll = math.random(1, 100)
    local success = roll <= successChance
    
    Isaac.DebugString("[Devil's Coin] Luck: " .. player.Luck .. " | Success Chance: " .. successChance .. "% | Roll: " .. roll)
    
    -- Usando GetRoomEntities de forma segura
    local room = game:GetRoom()
    local entities = Isaac.GetRoomEntities()
    local pickups = {}
    
    -- Iteração correta sobre a tabela Lua
    for _, entity in ipairs(entities) do
        if entity.Type == EntityType.ENTITY_PICKUP then
            local pickup = entity:ToPickup()
            if pickup then
                table.insert(pickups, {
                    pos = pickup.Position,
                    type = pickup.Type,
                    variant = pickup.Variant,
                    subtype = pickup.SubType,
                    entity = pickup
                })
            end
        end
    end
    
    Isaac.DebugString("[Devil's Coin] Encontrados " .. #pickups .. " pickups")
    
    if success then
        Isaac.DebugString("[Devil's Coin] SUCESSO! Duplicando...")
        
        -- Duplica todos os pickups
        for _, data in ipairs(pickups) do
            Isaac.Spawn(data.type, data.variant, data.subtype, data.pos, Vector.Zero, nil)
        end
        
        game:ShakeScreen(10)
        -- Usando som padrão ao invés de som customizado
        SFXManager():Play(SoundEffect.SOUND_SATAN_GROW, 1.0, 0, false, 1.0)
        
    else
        Isaac.DebugString("[Devil's Coin] FALHA! Removendo...")
        
        -- Remove todos os pickups
        for _, data in ipairs(pickups) do
            data.entity:Remove()
        end
        
        game:ShakeScreen(10)
        SFXManager():Play(SoundEffect.SOUND_DEVIL_CARD, 1.0, 0, false, 1.0)
    end
    
    return {
        Discharge = true,
        Remove = false,
        ShowAnim = true
    }
end

function mod:OnGameStart()
    DEVILS_COIN_ID = Isaac.GetItemIdByName("Devil's Coin")
    
    if DEVILS_COIN_ID and DEVILS_COIN_ID > 0 then
        Isaac.DebugString("[Devil's Coin] ID encontrado: " .. DEVILS_COIN_ID)
    else
        Isaac.DebugString("[Devil's Coin] ERRO: Item não encontrado!")
    end
end

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.OnGameStart)
mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.OnUseDevilsCoin)

Isaac.DebugString("[The Purgatory Package] Mod carregado!")
