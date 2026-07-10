PR = PR or {}
PR.Weather = PR.Weather or {}

PR.Weather.Resource = 'Renewed-Weathersync'

PR.Weather.Callbacks = {
    getState = 'forge-core:server:weather:getState',
    setWeather = 'forge-core:server:weather:setWeather',
    setDuration = 'forge-core:server:weather:setDuration',
    addWeather = 'forge-core:server:weather:addWeather',
    removeWeather = 'forge-core:server:weather:removeWeather',
    setTime = 'forge-core:server:weather:setTime',
    setTimeScale = 'forge-core:server:weather:setTimeScale',
    setFreezeTime = 'forge-core:server:weather:setFreezeTime',
}

PR.Weather.Types = {
    { label = 'Tempestade de neve', value = 'BLIZZARD' },
    { label = 'Limpo', value = 'CLEAR' },
    { label = 'Clareando', value = 'CLEARING' },
    { label = 'Nuvens', value = 'CLOUDS' },
    { label = 'Extra ensolarado', value = 'EXTRASUNNY' },
    { label = 'Nevoeiro', value = 'FOGGY' },
    { label = 'Neutro', value = 'NEUTRAL' },
    { label = 'Nublado', value = 'OVERCAST' },
    { label = 'Chuva', value = 'RAIN' },
    { label = 'Nevoeiro denso', value = 'SMOG' },
    { label = 'Neve', value = 'SNOW' },
    { label = 'Neve leve', value = 'SNOWLIGHT' },
    { label = 'Trovoada', value = 'THUNDER' },
    { label = 'Natal', value = 'XMAS' },
}
