// This code is from: https://github.com/camas/grunt/
const MURMUR2_CONST: u32 = 1_540_483_477;

pub(crate) fn calculate_hash(data: &[u8], seed: u32) -> u32 {
    let length = data.len();
    let mut h: u32 = seed ^ length as u32;
    let mut i: u32 = 0;
    let mut shift: i32 = 0;
    for b in data.iter() {
        i |= (*b as u32) << shift;
        shift += 8;
        if shift == 32 {
            i = i.wrapping_mul(MURMUR2_CONST);
            i ^= i >> 24;
            i = i.wrapping_mul(MURMUR2_CONST);
            h = h.wrapping_mul(MURMUR2_CONST);
            h ^= i;
            i = 0;
            shift = 0;
        }
    }
    if shift > 0 {
        h ^= i;
        h = h.wrapping_mul(MURMUR2_CONST);
    }
    h ^= h >> 13;
    h = h.wrapping_mul(MURMUR2_CONST);
    h ^ h >> 15
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_hash() {
        // Tests known result
        let data = b"##Interface:80300##Title:|cff00ff00TradeSkillMaster_AppHelper|r##Notes:ActsasaconnectionbetweentheTSMaddonandapp.##Author:TSMTeam##Version:v4.0.8##SavedVariables:TradeSkillMaster_AppHelperDB##Dependency:TradeSkillMasterTradeSkillMaster_AppHelper.luaAppData.lua";
        let res = calculate_hash(data, 1);
        assert_eq!(res, 851_628_572);
    }
}
