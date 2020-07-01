-- Scripts.lua
-- December 2014

local addon, ns = ...
local Hekili = _G[ addon ]

local class   = Hekili.Class
local scripts = Hekili.Scripts
local state   = Hekili.State

local GetResourceInfo, GetResourceID = ns.GetResourceInfo, ns.GetResourceID
local SpaceOut = ns.SpaceOut

local ceil = math.ceil
local orderedPairs = ns.orderedPairs
local roundUp = ns.roundUp
local safeMax = ns.safeMax

local trim = string.trim

local twipe = table.wipe


-- Forgive the name, but this should properly replace ! characters with not, accounting for appropriate bracketing.
-- Why so complex?  Because "! 0 > 1" converted to Lua is "not 0 > 1" which evaluates to "false > 1" -- not the goal.
-- This should convert:
-- example 1:  ! 0 > 1
--             not ( 0 > 1 )
--
-- example 2:  ! ( 0 > 1 & ! ( false | true ) )
--             not ( 0 > 1 & not ( false | true ) )
--
-- example 3:  ! cooldown.x.remains > 1 * ( gcd * ( 8 % 3 ) )
--             not ( cooldown.x.remains > 1 * ( gcd * ( 8 % 3 ) ) )
--
-- Hopefully.

local exprBreak = {
   ["&"] = true,
   ["|"] = true,
}

local function forgetMeNots( str )
   -- First, handle already bracketed "!(X)" -> "not (X)".
   local found = 1

   while found > 0 do
      str, found = str:gsub( "%s*!%s*(%b())%s*", " not %1 " )
   end

   -- The remaining conditions are not bracketed, but may include brackets.
   -- Such as !5>2+(1*3).
   -- So we'll start from the !, then go through the string until it's time to stop.

   local i = 1
   local substring

   while( str:find("!") ) do   
      local start = str:find("!")

      --while str:sub( start, start ):match("%s") do
      --   start = start + 1
      --      end

      local parens = 0
      local finish = -1

      for j = start, str:len() do
         local char = str:sub( j, j )

         if char == "(" then         
            parens = parens + 1

         elseif char == ")" then         
            if parens > 0 then parens = parens - 1
            else finish = j - 1; break end

         elseif parens == 0 then
            -- We are not within a bracketed part of the string.  We can end here.
            if exprBreak[ char ] then
               finish = j - 1
               break
            end
         end
      end

      if finish == -1 then finish = str:len() end

      substring = str:sub( start + 1, finish )
      substring = substring:trim()

      str = format( "%s not ( %s ) %s", str:sub( 1, start - 1 ) or "", substring, str:sub( finish + 1, str:len() ) or "" )

      i = i + 1
      if i >= 100 then Hekili:Debug( "Was unable to convert '!' to 'not' in string [%s].", str ); break end
   end

   str = str:gsub( "%s%s", " " )

   return str
end


local mathBreak = {
    ["<"] = true,
    [">"] = true,
    ["="] = true,
    ["&"] = true,
    ["|"] = true,
    [","] = true
}

local function HandleDeprecatedOperators( str, opStr, prefix  )
    --str = str:gsub("%s", "")
    for left, op, right in str:gmatch("(.+)(" .. opStr .. ")(.+)") do
        local leftLen, rightLen = left:len(), right:len()
        local val1, val2, len1, len2, b1, b2

        if left:sub(-1) == ")" then
            val1 = left:match("(%b())$")
            len1 = val1:len()
            val1 = val1:sub( 2, -2 )
        else
            -- We need to traverse the left side, backwards.
            local parens = 0
            local eos = -1

            for i = 1, leftLen do
                local char = left:sub(-i, -i)

                if char == ")" then
                    -- Grab the full bracketed pair and move on.
                    i = i + left:sub( 1, 1 + leftLen - i ):match( "(%b())$" ):len()
                elseif mathBreak[ char ] or char == "(" then
                    eos = i - 1
                    break
                end
            end

            if eos == -1 then
                val1 = left
                len1 = leftLen
            else
                val1 = left:sub( 1 + leftLen - eos, leftLen):trim()
                len1 = eos
            end
        end

        val1 = val1:trim()

        if right:sub(1, 1) == "(" then
            val2 = right:match("^(%b())")
            len2 = val2:len()
            val2 = val2:sub( 2, -2 )
        else
            local parens = 0
            local eos = -1

            for i = 1, right:len() do
                local char = right:sub(i, i)

                if char == "(" then
                    i = i + right:sub( i ):match("^(%b())" ):len()
                elseif mathBreak[char] or char == ")" then
                    eos = i - 1
                    break
                end
            end

            if eos == -1 then
                val2 = right
                len2 = rightLen
            else
                val2 = right:sub(1, eos)
                len2 = eos
            end
        end

        val2 = val2:trim()

        str = left:sub( 1, leftLen - len1 ) .. " " .. prefix .. "(safenum(" .. val1 .. "),safenum(" .. val2 .. ")) " .. right:sub( 1 + len2 )
    end

    return str
end
scripts.HandleDeprecatedOperators = HandleDeprecatedOperators


local invalid = "([^a-zA-Z0-9_.[])"


local function extendExpression( str, expr, suffix )
    if str:find( expr ) then
        str = str:gsub( "^" .. expr .. invalid, expr .. "." .. suffix .. "%1" )
        str = str:gsub( invalid .. expr .. "$", "%1" .. expr .. "." .. suffix )
        str = str:gsub( "^" .. expr .. "$", expr .. "." .. suffix )
        str = str:gsub( invalid .. expr .. invalid, "%1" .. expr .. "." .. suffix .. "%2" )
    end

    return str
end


local function SimcWithResources( str )
    for k in pairs( GetResourceInfo() ) do
        if str:find( k ) then
            str = extendExpression( str, k, "current" )
        end
    end

    if str:find( "health" ) then
        str = extendExpression( str, "health", "current" )
    end

    if str:find( "rune" ) then
        str = extendExpression( str, "rune", "current" )
    end

    if str:find( "spell_targets" ) then
        str = extendExpression( str, "spell_targets", "any" )
    end

    if str:find( "gcd" ) then
        str = extendExpression( str, "gcd", "execute" )
    end

    return str
end


local function space_killer(s)
    return s:gsub("%s", "")
end

-- Convert SimC syntax to Lua conditionals.
local function SimToLua( str, modifier )
    -- If no conditions were provided, function should return true.
    if not str or type( str ) == "number" then return str end

    local orig = str
    str = str:trim()

    if str == "" then return orig end

    -- Strip comments.
    str = str:gsub("^%-%-.-\n", "")

    -- Replace '!' with ' not '.
    if str:find("!") then str = forgetMeNots( str ) end

    -- Replace '>?' and '<?' with max/min.
    if str:find(">%?") then str = HandleDeprecatedOperators( str, ">%?", "max" ) end
    if str:find("<%?") then str = HandleDeprecatedOperators( str, "<%?", "min" ) end

    str = SimcWithResources( str )

    -- Replace '%' for division with actual division operator '/'.
    str = str:gsub("%%", "/")

    -- Replace '&' with ' and '.
    str = str:gsub("&", " and ")

    -- Replace '|' with ' or '.
    str = str:gsub("||", " or "):gsub("|", " or ")

    if not modifier then
        -- Replace assignment '=' with comparison '=='
        str = str:gsub("([^=])=([^=])", "%1==%2" )

        -- Fix any conditional '==' that got impacted by previous.
        str = str:gsub("==+", "==")
        str = str:gsub(">=+", ">=")
        str = str:gsub("<=+", "<=")
        str = str:gsub("!=+", "~=")
        str = str:gsub("~=+", "~=")
    end

    -- Condense whitespace.
    str = str:gsub("%s%s", " ")

    -- Condense parenthetical spaces.
    str = str:gsub("[(][%s+]", "("):gsub("[%s+][)]", ")")

    -- Address equipped.number => equipped[number]
    str = str:gsub("%.(%d+)%.", "[%1].")
    str = str:gsub("equipped%.(%d+)", "equipped[%1]")
    str = str:gsub("lowest_vuln_within%.(%d+)", "lowest_vuln_within[%1]")
    str = str:gsub("%.in([^a-zA-Z0-9_])", "['in']%1" )
    str = str:gsub("%.in$", "['in']" )
    str = str:gsub("imps_spawned_during%.([^!=<>&|]+)", "imps_spawned_during['%1'] ")
    str = str:gsub("time_to_imps%.(%b()).remains", "time_to_imps[%1].remains")
    str = str:gsub("time_to_imps%.(%d+).remains", "time_to_imps[%1].remains")
    -- str = str:gsub("incanters_flow_time_to%.(%d+)[.any]?", "incanters_flow_time_to[%1]")

    -- Condense bracketed expressions.
    str = str:gsub("%b[]", space_killer)

    str = str:gsub("prev%.(%d+)", "prev[%1]")
    str = str:gsub("prev_gcd%.(%d+)", "prev_gcd[%1]")
    str = str:gsub("prev_off_gcd%.(%d+)", "prev_off_gcd[%1]")
    str = str:gsub("time_to_sht%.(%d+)", "time_to_sht[%1]")

    --str = SpaceOut( str )

    return str
end
scripts.SimToLua = SimToLua


do
    -- Okay, this is the auto-recheck parser.

    -- Part I:  Split into parts.
    -- ex. combo_points<5&energy>=action.rake.cost&dot.rake.pmultiplier<2.1&buff.tigers_fury.up&(buff.bloodtalons.up|!talent.bloodtalons.enabled)&(!talent.incarnation.enabled|cooldown.incarnation.remains>18)&!buff.incarnation.up
    -- ...and break it into each compartmentalized expression:
    -- combo_points<5, energy>=action.rake.cost, dot.rake_multiplier<2.1.

    local boundaries = {
        ["&"] = true,
        ["|"] = true
    }

    function scripts:SplitExpr( str )
        local output = {}

        while( str:len() > 0 ) do
            local finish = str:len()
            local parens = 0

            for i = 1, str:len() do
                local char = str:sub( i, i )
                if char == "(" then parens = parens + 1
                elseif char == ")" then
                    if parens > 0 then parens = parens - 1 end
                elseif boundaries[ char ] and parens == 0 then
                    finish = i - 1
                    break
                end
            end

            local expr = str:sub( 1, finish )

            local meat = expr:match( "(%b())" )
            if meat then
                meat = meat:sub( 2, -2 )

                if meat:find( "[|&]" ) then
                    local subExpr = scripts:SplitExpr( meat )

                    for _, v in ipairs( subExpr ) do
                        table.insert( output, v )
                    end
                else
                    table.insert( output, expr )
                end
            else
                table.insert( output, expr )
            end
            str = str:sub( finish + 2, str:len() )
        end

        return output
    end

    local timely = {
        { "^(d?e?buff%.[a-z0-9_]+)%.down",          "%1.remains" },
        { "^(dot%.[a-z0-9_]+)%.down",               "%1.remains" },
        { "!(d?e?buff%.[a-z0-9_]+)%.up",            "%1.remains" },
        { "!(dot%.[a-z0-9_]+)%.up",                 "%1.remains" },
        { "!(d?e?buff%.[a-z0-9_]+)%.react",         "%1.remains" },
        { "!(dot%.[a-z0-9_]+)%.react",              "%1.remains" },
        { "!(d?e?buff%.[a-z0-9_]+)%.ticking",       "%1.remains" },
        { "!(dot%.[a-z0-9_]+)%.ticking",            "%1.remains" },
        { "!?(d?e?buff%.[a-z0-9_]+)%.remains",      "%1.remains" },
        { "!ticking",                               "remains" },
        { "^!?remains$",                            "remains" },
        { "^refreshable",                           "time_to_refresh" },
        
        { "^(.-)%.deficit<=?(.-)$",                 "%1.timeTo(%1.max-(%2))" },
        { "^(.-)%.deficit>=?(.-)$",                 "%1.timeTo(%1.max-(%2))" },        
        
        { "^cooldown%.([a-z0-9_]+)%.ready$",        "cooldown.%1.remains" },
        { "^cooldown%.([a-z0-9_]+)%.up$",           "cooldown.%1.remains" },
        { "^!?cooldown%.([a-z0-9_]+)%.remains$",    "cooldown.%1.remains" },
        
        { "^charges_fractional[>=]+(.-)$",          "(%1-charges_fractional)*recharge" },
        { "^charges>=?(.-)$",                       "(1+%1-charges_fractional)*recharge" },
        { "^(cooldown%.[a-z0-9_]+)%.charges_fractional[>=]+(.-)$",
                                                    "(%2-%1.charges_fractional)*%1.recharge" },
        { "^(cooldown%.[a-z0-9_]+)%.charges>=?(.-)$",
                                                    "(1+%2-%1.charges_fractional)*recharge" },
        { "^(action%.[a-z0-9_]+)%.charges_fractional[>=]+(.-)$",
                                                    "(%2-%1.charges_fractional)*%1.recharge" },
        { "^(action%.[a-z0-9_]+)%.charges>=?(.-)$",
                                                    "(1+%2-%1.charges_fractional)*%1.recharge" },
        
        { "^!(action%.[a-z0-9]+)%.executing$",      "%1.execute_remains" },
        { "^(.-time_to_die)<=?(.-)$",               "%1 - %2" },
        { "^(.-)%.time_to_(.-)<=?(.-)$",            "%1.time_to_%2-%3" },

        { "^debuff%.festering_wound%.stack[>=]=?(.-)$", -- UH DK helper during Unholy Frenzy.
                                                    "time_to_wounds(%1)" },
        { "^dot%.festering_wound%.stack[>=]=?(.-)$",    -- UH DK helper during Unholy Frenzy.
                                                    "time_to_wounds(%1)" },

        { "^exsanguinated$",                        "remains" }, -- Assassination
        { "^!?(debuff%.[a-z0-9_]+)%.exsanguinated$",
                                                    "%1.remains" }, -- Assassination
        { "^!?(dot%.[a-z0-9_]+)%.exsanguinated$",   "%1.remains" }, -- Assassination
        { "^ss_buffed",                             "remains" }, -- Assassination
        { "^!?(debuff%.[a-z0-9_]+)%.ss_buffed$",
                                                    "%1.remains" }, -- Assassination
        { "^!?(dot%.[a-z0-9_]+)%.ss_buffed$",       "%1.remains" }, -- Assassination
        { "^!?consecration.up",                     "consecration.remains" }, -- Prot Paladin
        { "^!?contagion<=?(.-)",                    "contagion-%1" }, -- Affliction Warlock
        
    { "^!?action%.([a-z0-9_]+)%.in_flight$",        "action.%1.in_flight_remains" }, -- Fire Mage, but others too, potentially.
        { "^!?action%.([a-z0-9_]+)%.in_flight_remains<=?(.-)$",
                                                    "action.%1.in_flight_remains-%2" }, -- Fire Mage, but others too, potentially.
        { "^!?variable.time_to_combustion$",        "variable.time_to_combustion" },
        { "^!?variable.time_to_combustion<=?(.-)$",
                                                    "variable.time_to_combustion-%1" },

        { "^!?(pet%.[a-z0-9_]+)%.up",               "%1.remains" },
        { "^!?(pet%.[a-z0-9_]+)%.active",           "%1.remains" },
    }

    -- Things that tick down.
    local decreases = {
        ["remains$"] = true,
        ["ticks_remain$"] = true,
        ["execute_remains$"] = true,
        -- ["time_to_%d+$"] = true,
        -- ["deficit$"] = true,
    }

    -- Things that tick up.
    local increases = {
        ["^time$"] = true,
        ["charges"] = true,
        ["charges_fractional"] = true,        
    }

    local removals = {
        ["%.current"] = ""
    }

    local lessOrEqual = {
        -- ["<"] = true,
        ["<="] = true,
        ["="] = true,
        ["=="] = true
    }

    local moreOrEqual = {
        -- [">"] = true,
        [">="] = true,
        ["="] = true,
        ["=="] = true
    }


    -- Given an expression, can we assess whether it is time-based and progressing in a meaningful way?
    -- 1.  Cooldowns
    local function ConvertTimeComparison( expr, verbose )
        for k, v in pairs( removals ) do
            expr = expr:gsub( k, v )
        end

        local bracketed = expr:match( "(%b())" )
        if bracketed and bracketed:len() == expr:len() then
            expr = expr:sub( 2, -2 )
        end

        local lhs, comp, rhs = expr:match( "^(.-)([<>=?]+)(.-)$" )

        if comp and comp:match( "?" ) then
            comp = nil
        end

        if lhs and comp and rhs then
            -- We are looking at a mathematic comparison.
            for key in pairs( decreases ) do
                if lhs:match( key ) then
                    if comp == "<" then
                        return true, lhs .. " + 0.01 - " .. rhs
                    elseif lessOrEqual[ comp ] then
                        return true, lhs .. " - " .. rhs
                    end
                end
            end

            for key in pairs( increases ) do
                if lhs:match( key ) then
                    if comp == ">" then
                        return true, rhs .. " + 0.01 - " .. rhs
                    elseif moreOrEqual[ comp ] then
                        return true, rhs .. " - " .. lhs
                    end
                end
            end

            -- resources also tick up (usually, anyway)
            for key in pairs( GetResourceInfo() ) do
                if lhs == key then
                    if comp == ">" then
                        return true, "0.01 + " .. lhs .. ".timeTo( " .. rhs .. " )"
                    elseif moreOrEqual[ comp ] then
                        return true, lhs .. ".timeTo( " .. rhs .. " )"
                    end
                end

                if rhs == key then
                    if comp == "<" then
                        return true, "0.01 + " .. rhs .. ".timeTo( " .. rhs .. " )"
                    elseif lessOrEqual[ comp ] then
                        return true, rhs .. ".timeTo( " .. lhs .. " )"
                    end
                end
            end

            if lhs == "rune" then
                if comp == ">" then
                    return true, "0.01 + rune.timeTo( " .. rhs .. " )"
                elseif moreOrEqual[ comp ] then
                    return true, "rune.timeTo( " .. rhs .. " )"
                end
            end

            if rhs == "rune" then
                if comp == "<" then
                    return true, "0.01 + rune.timeTo( " .. lhs .. " )"
                elseif lessOrEqual[ comp ] then
                    return true, "rune.timeTo( " .. lhs .. " )"
                end
            end
        end

        for i, swap in ipairs( timely ) do
            if expr:match( swap[1] ) then
                return true, expr:gsub( swap[1], swap[2] )
            end
        end

        return false, nil
    end

    scripts.CTC = ConvertTimeComparison

    function scripts:RecheckExpr( expr )
        return ConvertTimeComparison( expr )
    end

    function scripts:BuildRecheck( conditions )
        local recheck

        conditions = conditions:gsub( " +", "" )
        conditions = self:EmulateSyntax( conditions, true )

        local exprs = self:SplitExpr( conditions )

        if #exprs > 0 then            
            for i, expr in ipairs( exprs ) do
                local converted, calc = ConvertTimeComparison( expr )

                if converted then
                    -- calc = self:EmulateSyntax( calc, true )
                    recheck = ( recheck and ( recheck .. ", " ) or "return " ) .. calc
                end
            end
        end

        return recheck
    end


    local ops = {
        ["+"] = true,
        ["-"] = true,
        ["*"] = true,
        ["/"] = true,
        ["%"] = true,
        ["|"] = true,
        ["&"] = true,
        ["<"] = true,
        [">"] = true,
        ["?"] = true,
        ["="] = true,
        ["!"] = true,
     }

     local math_ops = {
        ["+"] = true,
        ["-"] = true,
        ["*"] = true,
        ["/"] = true,
        ["%"] = true,
        ["<"] = true,
        [">"] = true,
        ["="] = true
     }

     local comp_ops = {
        ["<"] = true,
        [">"] = true,
        ["="] = true,
        ["?"] = true,
     }

     local bool_ops = {
         ["|"] = true,
         ["&"] = true,
         ["!"] = true
     }


     -- This is hideous.

     local esDepth = 0
     local esString

     function scripts:EmulateSyntax( p, numeric )
        if not p or type( p ) ~= "string" then return p end

        if esDepth == 0 then
            esString = p
        end
        esDepth = esDepth + 1

        local results = {}

        local i, maxlen = 1, p:len()
        local depth = 0

        local bracketed = p:match("(%b())" ) == p
        if bracketed then
            p = p:sub( 2, p:len() - 1 )
        end

        local ands = p:find( " and " )
        local ors = p:find( " or " )
        local nots = p:find( " not " )

        if ands then p = p:gsub( " and ", "&" ) end
        if ors then p = p:gsub( " or ", "|" ) end
        if nots then p = p:gsub( " not ", "!" ) end

        p = p:gsub( "([!%|&%-%+%*=%%/<>%?]) +", "%1" )
        p = p:gsub( " +([!%|&%-%+%*=%%/<>%?])", "%1" )

        local orig = p

        while ( i <= maxlen ) do
           local c = p:sub( i, i )

           if c == " " then -- do nothing
           elseif c == "(" then depth = depth + 1
           elseif c == ")" and depth > 0 then
              depth = depth - 1

              if depth == 0 then
                 local expr = p:sub( 1, i )

                 table.insert( results, { 
                       s = expr:trim(),
                       t = "expr"
                 } )

                 if expr:find( "[&%|%-%+/%%%*]" ) ~= nil then results[#results].r = true end

                 p = p:sub( i + 1 )
                 i = 0
                 depth = 0
                 maxlen = p:len()
              end
           elseif depth == 0 and ops[c] then
              if i > 1 then
                 local expr = p:sub( 1, i - 1 )

                 table.insert( results, {
                       s = expr:trim(),
                       t = "expr"
                 } )

                 if expr:find( "[&$|$-$+/$%%*]" ) ~= nil then results[#results].r = true end
              end

              c = p:sub( i ):match( "^([&%|%-%+*%%/><=!%?]+)" )

              table.insert( results, {
                    s = c,
                    t = "op",
                    a = c:sub(1,1)
              } )

              p = p:sub( i + c:len() )
              i = 0
              depth = 0
              maxlen = p:len()
           end

           i = i + 1
        end

        p = p:trim()

        if p:len() > 0 then
           table.insert( results, {
                 s = p:trim(),
                 t = "expr",
                 l = true
           } )

           if p:find( "[!&%|%-%+/%%%*]" ) ~= nil then results[#results].r = true end
        end

        local output = ""

        -- So at this point, we've broken our string into all of its components.  Now let's iterate through and fix it up.
        for i = 1, #results do
            local prev, piece, next = i > 1 and results[i-1] or nil, results[i], i < #results and results[i+1] or nil

            if piece.t == "expr" then
                if piece.r then
                    if piece.s == orig then
                        if bracketed then orig = "(" .. orig .. ")" end
                        if ands then orig = orig:gsub( "&", " and " ) end
                        if ors then orig = orig:gsub( "|", " or " ) end
                        esDepth = esDepth - 1
                        return orig 
                    end
                    piece.s = scripts:EmulateSyntax( piece.s, numeric )
                end

                if ( prev and prev.t == "op" and math_ops[ prev.a ] ) or ( next and next.t == "op" and math_ops[ next.a ] ) then
                    -- This expression is getting mathed.
                    -- Lets see what it returns and wrap it in btoi if it is a boolean expr.
                    if piece.s:find("^variable") then
                        -- Let's wrap the variable just to be sure.
                        piece.s = "safenum(" .. piece.s .. ")"
                    else
                        local func, warn = loadstring( "return " .. ( SimToLua( piece.s ) or "" ) )
                        if func then
                            setfenv( func, state )
                            -- maximum warningness
                            local pass, val = pcall( func )
                            if not pass and not piece.s:match("variable") then
                                local safepiece = piece.s:gsub( "%%", "%%%%" )
                                Hekili:Error( "Unable to compile '" .. safepiece .. "' - " .. val .. " (pcall-n)\nFrom: " .. esString:gsub( "%%", "%%%%" ) )
                            else if val == nil or type( val ) == "boolean" then piece.s = "safenum(" .. piece.s .. ")" end end
                        else
                            Hekili:Error( "Unable to compile '" .. ( piece.s ):gsub("%%","%%%%") .. "' - " .. warn .. " (loadstring-n)\nFrom: " .. esString:gsub( "%%", "%%%%" ) )
                        end
                    end
                    piece.r = nil

                elseif not numeric and ( not prev or ( prev.t == "op" and not math_ops[ prev.a ] )  ) and ( not next or ( next.t == "op" and not math_ops[ next.a ] ) ) then
                    -- This expression is not having math operations performed on it.
                    -- Let's make sure it's a boolean.                
                    if piece.s:find("^variable") then
                        piece.s = "safebool(" .. piece.s .. ")"
                    else    
                        local func, warn = loadstring( "return " .. ( SimToLua( piece.s ) or "" ) )
                        if func  then
                            setfenv( func, state )
                            local pass, val = pcall( func )
                            if not pass and not piece.s:match("variable") then
                                local safepiece = piece.s:gsub( "%%", "%%%%" )
                                Hekili:Error( "Unable to compile '" .. safepiece .. "' - " .. val .. " (pcall-b)\nFrom: " .. esString:gsub( "%%", "%%%%" ) )
                            else if val == nil or type( val ) == "number" then piece.s = "safebool(" .. piece.s .. ")" end end
                        else
                            Hekili:Error( "Unable to compile '" .. ( piece.s ):gsub("%%","%%%%") .. "' - " .. warn .. " (loadstring-b)." )
                        end                        
                    end
                    piece.r = nil
                end 
            end

           output = output .. piece.s
        end

        if bracketed then output = "(" .. output .. ")" end
        if ands then output = output:gsub( "&", " and " ) end
        if ors then output = output:gsub( "|", " or " ) end
        if nots then output = output:gsub( "!", " not " ) end

        -- output = output:gsub( "  ", " " )
        -- output = output:gsub( "not (safenum(", "safenum(not (" )
        -- output = output:gsub( "not safebool(", "safebool(not " )        
        output = output:gsub( "!safenum(%b())", "safenum(!%1)" )
        output = output:gsub( "!%((%b())%)", "!%1" )

        esDepth = esDepth - 1
        return output
     end
end


-- Convert SimC syntax to Lua conditionals.
local function SimCToSnapshot( str, modifier )
    -- If no conditions were provided, function should return true.
    if not str or str == '' then return nil end
    if type( str ) == 'number' then return str end

    str = str:trim()

    -- Strip comments.
    str = str:gsub("^%-%-.-\n", "")

    -- Replace '!' with ' not '.
    -- str = forgetMeNots( str )

    str = SimcWithResources( str )

    -- Replace '%' for division with actual division operator '/'.
    -- str = str:gsub("%%", "/")

    -- Replace '&' with ' and '.
    -- str = str:gsub("&", " and ")

    -- Replace '|' with ' or '.
    -- str = str:gsub("||", " or "):gsub("|", " or ")

    --[[ if not modifier then
        -- Replace assignment '=' with comparison '=='
        str = str:gsub("([^=])=([^=])", "%1==%2" )

        -- Fix any conditional '==' that got impacted by previous.
        str = str:gsub("==+", "==")
        str = str:gsub(">=+", ">=")
        str = str:gsub("<=+", "<=")
        str = str:gsub("!=+", "~=")
        str = str:gsub("~=+", "~=")
    end 

    -- Condense whitespace.
    str = str:gsub("%s%s", " ")

    -- Condense parenthetical spaces.
    str = str:gsub("[(][%s+]", "("):gsub("[%s+][)]", ")") ]]

    -- Address equipped.number => equipped[number]
    str = str:gsub("equipped%.(%d+)", "equipped[%1]")
    str = str:gsub("lowest_vuln_within%.(%d+)", "lowest_vuln_within[%1]")
    str = str:gsub("%.in([^a-zA-Z0-9_])", "['in']%1" )
    str = str:gsub("%.in$", "['in']" )

    str = str:gsub("imps_spawned_during%.([^<>=!&|]+)", "imps_spawned_during[%1]")

    str = str:gsub("prev%.(%d+)", "prev[%1]")
    str = str:gsub("prev_gcd%.(%d+)", "prev_gcd[%1]")
    str = str:gsub("prev_off_gcd%.(%d+)", "prev_off_gcd[%1]")
    str = str:gsub("time_to_sht%.(%d+)", "time_to_sht[%1]")

    return str

end


local function stripScript( str, thorough )
  if not str then return 'true' end
  if type( str ) == 'number' then return str end

  -- Remove the 'return ' that was added during conversion.
  str = str:gsub("^return ", "")

  -- Remove min/max/safenum/safebool.
  str = str:gsub("([^%a%w_%.])min([^%a%w_)]+)%s?%(?", "%1%2 "):gsub("([^%a%w_%.])max([^%a%w_)]+)%s?%(?", "%1%2 "):gsub("([^%a%w_%.])safebool([^%a%w_)]+)%s?%(?", "%1%2 "):gsub("([^%a%w_%.])safenum([^%a%w_)]+)%s?%(?", "%1%2 ")

  -- Remove comments and parentheses.
  str = str:gsub("%-%-.-\n", ""):gsub("[()]", "")

  -- Remove conjunctions.
  str = str:gsub("[%s-]and[%s-]", " "):gsub("[%s-]or[%s-]", " "):gsub("%(-%s-not[%s-]", " ")

  if not thorough then
    -- Collapse whitespace around comparison operators.
    str = str:gsub("[%s-]==[%s-]", "=="):gsub("[%s-]>=[%s-]", ">="):gsub("[%s-]<=[%s-]", "<="):gsub("[%s-]~=[%s-]", "~="):gsub("[%s-]<[%s-]", "<"):gsub("[%s-]>[%s-]", ">")
  else
    str = str:gsub("[=+]", " "):gsub("[><~]%??", " "):gsub("[%*//%-%+]", " ")
  end

  str = str:gsub( "([%a%w_])%.(%d+)", "%1[%2]" )
  str = str:gsub( "%.in([ %.])", "['in']%1")

  -- Collapse the rest of the whitespace.
  str = str:gsub("[%s+]", " ")

  return ( str )
end


function scripts:StoreValues( tbl, node, mod )
    wipe( tbl )

    if type( node ) == 'string' then node = self.DB[ node ] end
    if not node then return end

    local elems
    if mod then elems = node.ModElements[ mod ]
    else elems = node.Elements end

    if not elems then return end

    for k, v in pairs( elems ) do
        local s, r = pcall( v )

        if s then tbl[ k ] = r
        elseif type( r ) == 'string' then tbl[ k ] = r:match( "lua:(%d+: .*)" ) or r end
        if tbl[ k ] == nil then tbl[ k ] = 'nil' end
    end
end


function scripts:StoreReadyValues( tbl, node )
    self:StoreValues( tbl, node, "ready" )
end


function scripts:GetScript( scriptID )
    return self.DB[ scriptID ]
end


local function GetScriptElements( script )
    if type( script ) == 'number' then return end

    local e, c = {}, stripScript( script, true )

    for s in c:gmatch( "[^ ,]+" ) do
        if not e[ s ] and not tonumber( s ) then
            local ef = loadstring( 'return '.. ( s or true ) )
            if ef then setfenv( ef, state ) end

            local success, v = pcall( ef )
            e[ s ] = ef
        end
    end

    return e
end
scripts.GetScriptElements = GetScriptElements


-- newModifiers, key is the name of the element, value is whether to babyproof it or not.
local newModifiers = {
    chain = 'bool',
    cycle_targets = 'bool',
    early_chain_if = 'bool',
    for_next = 'bool',
    interrupt = 'bool',
    interrupt_global = 'bool',
    interrupt_if = 'bool',
    interrupt_immediate = 'bool',
    moving = 'bool',
    strict = 'bool',
    target_if = 'bool',
    use_off_gcd = 'bool',
    use_while_casting = 'bool',
    wait = 'bool',

    -- Not necessarily a number, but not baby-proofed.
    default = 'raw',
    line_cd = 'raw',
    max_cycle_targets = 'raw',
    sec = 'raw',
    value = 'raw',
    value_else = 'raw',

    sync = 'string', -- should be an ability's name.
    buff_name = 'string',
    list_name = 'string',
    op = 'string',
    potion = 'string',
    var_name = 'string',
}


local valueModifiers = {
    sec = true,
    value = true,
    value_else = true,
    line_cd = true,
    max_cycle_targets = true
}


--[[ local nameMap = {
    call_action_list = "list_name",
    run_action_list = "list_name",
    variable = "var_name",
    potion = "potion",
    cancel_buff = "buff_name",
} ]]


local isString = {
    op = true,
}


-- Need to convert all the appropriate scripts and store them safely...
local function ConvertScript( node, hasModifiers, header )
    local previousScript = state.scriptID
    state.scriptID = header

    state.this_action = node.action

    local t = node.criteria and node.criteria ~= "" and node.criteria
    local clean = SimToLua( t )

    t = scripts:EmulateSyntax( t )
    t = SimToLua( t )

    local sf, e

    if t then sf, e = loadstring( "-- " .. header .. "\nreturn safebool( " .. t .. " )" ) end
    if sf then setfenv( sf, state ) end

    --[[ if sf and not e then
        local pass, val = pcall( sf )
        if not pass then e = val end
    end ]]

    if sf and not e then
        local success, msg = pcall( sf )
        if not success then e = msg end
    end
    if e then e = e:match( ":(%d+: .*)" ) or e end

    local se = clean and GetScriptElements( clean )

    local varPool

    if se then
        for k, v in pairs( se ) do
            if k:sub( 1, 8 ) == "variable" then
                varPool = varPool or {}
                table.insert( varPool, k:sub( 10 ) )
            end
        end
    end

    -- autorecheck...    
    local rs, rc, erc
    if t and t ~= "" then        
        rs = scripts:BuildRecheck( node.criteria )
        if rs then 
            rs = SimToLua( rs )
            rc, erc = loadstring( "-- " .. header .. " recheck\n" .. rs )
            if rc then setfenv( rc, state ) end

            if type( rc ) ~= "function" then
                Hekili:Error( "Recheck function for " .. node.criteria .. " ( " .. ( rs or "nil" ) .. ") was unsuccessful somehow." )
                rc = nil
            end    
        end
    end

    local output = {
        Conditions = sf,
        Error = e,
        Recheck = rc,
        RecheckScript = rs,
        RecheckError = erc,
        Elements = se,
        Modifiers = {},
        ModElements = {},
        ModEmulates = {},
        ModSimC = {},
        SpecialMods = "",

        Variables = varPool,

        Lua = clean and clean:trim() or nil,
        Emulated = t and t:trim() or nil,
        SimC = node.criteria and SimcWithResources( node.criteria:trim() ) or nil,        
    }

    if hasModifiers then
        for m, value in pairs( newModifiers ) do
            if node[ m ] then
                local emulated
                local o = SimToLua( node[ m ] )
                output.SpecialMods = output.SpecialMods .. " - " .. m .. " : " .. o

                local sf, e

                if value == 'bool' then
                    emulated = SimToLua( scripts:EmulateSyntax( node[ m ] ) )
                
                elseif value == 'raw' then
                    emulated = SimToLua( scripts:EmulateSyntax( node[ m ], true ) )

                else -- string
                    o = "'" .. o .. "'"
                    emulated = o

                end

                if node.action == "variable" then
                    local var_val, var_recheck, var_err
                    var_val = scripts:BuildRecheck( node[m] )
                    if var_val then
                        var_val = SimToLua( var_val )
                        var_recheck, var_err = loadstring( "-- val " ..header .. " recheck\n" .. var_val )
                        if var_recheck then setfenv( var_recheck, state ) end

                        if type( var_recheck ) ~= "function" then
                            Hekili:Error( "Variable recheck function for " .. node.criteria .. " ( " .. ( var_recheck or "nil" ) .. " ) was unsuccessful somehow." )
                            var_recheck = nil
                        end

                        output.VarRecheck = var_recheck
                        output.VarRecheckScript = var_val
                        output.VarRecheckError = var_err
                    end
                end

                sf, e = loadstring( "return " .. emulated )

                if sf then
                    setfenv( sf, state )
                    output.Modifiers[ m ] = sf
                    output.ModElements[ m ] = GetScriptElements( o )
                    output.ModEmulates[ m ] = emulated
                    if type( node[ m ] ) == 'string' then output.ModSimC[ m ] = SimcWithResources( node[ m ]:trim() ) end
                else
                    output.Modifiers[ m ] = e
                end
            end
        end

        --[[ local name = nameMap[ node.action ]
        if name and node[ name ] then
            -- local bitwrapped = SimToLua( scripts:EmulateSyntax( node[ name ] ) )
            local o = tostring( node[ name ] )
            o = "'" .. o .. "'"
            output.SpecialMods = output.SpecialMods .. " - " .. name .. " : " .. o

            local sf, e
            sf, e = loadstring( "return " .. o )

            if sf then
                setfenv( sf, state )
                output.Modifiers[ name ] = sf
                output.ModElements[ name ] = GetScriptElements( o )
            else
                output.Modifiers[ name ] = e
            end
        end ]]
    end

    state.scriptID = previousScript
    return output
end
scripts.ConvertScript = ConvertScript


do
    local cacheTime = 0
    local cache = {}

    function scripts:CheckScript( scriptID, action, elem )
        local moment = state.now + state.offset

        if moment ~= cacheTime then
            if Hekili.ActiveDebug then Hekili:Debug( "Resetting CheckScript cache as time changed from %.2f to %.2f ( %.2f ).", cacheTime, moment, moment - cacheTime ) end
            cacheTime = moment
            twipe( cache )
        end

        local uniqueID = scriptID .. "-" .. state.query_time
        if cache[ uniqueID ] ~= nil then return cache[ uniqueID ] end

        local prev_action = state.this_action
        if action then state.this_action = action end

        local script = self.DB[ scriptID ]

        if not script then
            state.this_action = prev_action
            cache[ uniqueID ] = false
            return false
        end

        if not elem then
            if script.Error then
                state.this_action = prev_action
                cache[ uniqueID ] = false
                return false, script.Error

            elseif not script.Conditions then
                state.this_action = prev_action
                cache[ uniqueID ] = true
                return true

            else
                -- local success, value = pcall( script.Conditions )
                local success, value = true, script.Conditions()

                if success then
                    state.this_action = prev_action
                    cache[ uniqueID ] = value
                    return value
                end
            end

        else
            if not script.Modifiers[ elem ] then
                state.this_action = prev_action
                return nil, elem .. " not set."

            else
                local success, value = pcall( script.Modifiers[ elem ] )

                if success then
                    state.this_action = prev_action
                    return value
                end
            end
        end

        state.this_action = prev_action
        cache[ uniqueID ] = false
        return false
    end

    function scripts:ResetCache()
        twipe( cache )
    end
end


function scripts:CheckVariable( scriptID )
    local script = self.DB[ scriptID ]

    if not script then
        return false, "no script"

    elseif script.Error then
        return false, script.Error

    end

    local mods = script.Modifiers

    if mods.value then
        local s, val = pcall( mods.value )
        if s then return val end
    end

    return false, "no op or error"
end


function scripts:IsTimeSensitive( scriptID )
    local s = self.DB[ scriptID ]

    return s and s.TimeSensitive
end


function scripts:GetModifiers( scriptID, out )
    out = out or {}

    local script = self.DB[ scriptID ]

    if not script then return out end

    for k, v in pairs( script.Modifiers ) do
        local success, value = pcall(v)
        if success then out[k] = value end
    end

    return out
end


local scriptsLoaded = false

local function scriptLoader()
    if not scriptsLoaded then scripts:LoadScripts() end
end


local channelModifiers = {
    interrupt = 1,
    interrupt_if = 1,
    interrupt_immediate = 1,
    interrupt_global = 1,
    chain = 1,
    early_chain_if = 1,
}


function scripts:SwapScripts( s1, s2 )
    local swap = scripts.DB[ s1 ]
    scripts.DB[ s1 ] = scripts.DB[ s2 ]
    scripts.DB[ s2 ] = swap
end


function scripts:LoadScripts()
    if not Hekili.PLAYER_ENTERING_WORLD then
        C_Timer.After( 1, scriptLoader )
        return
    end

    local profile = Hekili.DB.profile
    wipe( self.DB )
    wipe( self.Channels )
    wipe( self.PackInfo )

    Hekili.LoadingScripts = true

    state.reset()

    for pack, pData in pairs( profile.packs ) do
        local specData = pData.spec and class.specs[ pData.spec ]

        if specData then
            self.PackInfo[ pack ] = {
                items = {},
                essences = {}
            }

            for list, lData in pairs( pData.lists ) do
                for action, data in ipairs( lData ) do
                    local scriptID = pack .. ":" .. list .. ":" .. action

                    local script = ConvertScript( data, true, scriptID )

                    if script.Error then
                        Hekili:Error( "Error in " .. scriptID .. " conditions:  " .. script.Error )
                    end

                    if data.action == "call_action_list" or data.action == "run_action_list" then
                        -- Check for Time Sensitive conditions.
                        script.TimeSensitive = false

                        local lua = script.Lua

                        if lua then 
                            -- If resources are checked, it's time-sensitive.
                            for k in pairs( GetResourceInfo() ) do
                                local resource = rawget( state, k )
                                if lua:find( k ) and resource and ( resource.regenModel or resource.regen ~= 0 ) then script.TimeSensitive = true; break end 
                                -- if lua:find( k ) then script.TimeSensitive = true; break end
                            end

                            if lua:find( "rune" ) then script.TimeSensitive = true end

                            if not script.TimeSensitive then
                                -- Check for other time-sensitive variables.
                                if lua:find( "time" ) or lua:find( "cooldown" ) or lua:find( "charge" ) or lua:find( "remain" ) or lua:find( "up" ) or lua:find( "down" ) or lua:find( "ticking" ) or lua:find( "refreshable" ) then
                                    script.TimeSensitive = true
                                end
                            end
                        end
                    end

                    local ability

                    if data.action then
                        ability = specData.abilities[ data.action ] or class.abilities[ data.action ]
                    end

                    if ability then
                        if ability.channeled then
                            if not self.Channels[ pack ] then self.Channels[ pack ] = {} end
                            if not self.Channels[ pack ][ data.action ] then 
                                self.Channels[ pack ][ data.action ] = {}
                            end

                            local cInfo = self.Channels[ pack ][ data.action ]

                            -- This will load the channel criteria for the first entry for this ability in any of the action lists.
                            -- This seems OK as long as channel breakage criteria is based on the same logic for the same spell.
                            -- There's genuinely no way to know if a person is channeling Mind Flay because it was recommended, or just because they felt like it.

                            for k in pairs( channelModifiers ) do
                                if script.Modifiers[ k ] and not cInfo[ k ] then cInfo[ k ] = script.Modifiers[ k ] end
                            end
                        end

                        if ability.item and data.enabled then
                            self.PackInfo[ pack ].items[ data.action ] = true
                        end

                        if ability.essence and data.enabled then
                            self.PackInfo[ pack ].essences[ data.action ] = true
                        end
                    end

                    self.DB[ scriptID ] = script
                end
            end
        end
    end

    Hekili.LoadingScripts = false
    scriptsLoaded = true
end


function Hekili:LoadScripts()
    self.Scripts:LoadScripts()
    self:UpdateUseItems()
    self:UpdateDisplayVisibility()
end


function Hekili:IsEssenceScripted( token )
    local pack = self:GetActivePack()
    pack = pack and self.Scripts.PackInfo[ pack ]

    if not pack then return false end

    return pack.essences[ token ] or false
end


function Hekili:IsItemScripted( token )
    local pack = Hekili:GetActivePack()
    if not pack then return false end
    if not self.Scripts.PackInfo[ pack ] then return false end

    return self.Scripts.PackInfo[ pack ].items[ token ] or false
end


function Hekili.Scripts:LoadItemScripts()
    for k in pairs( self.DB ) do
        if k:sub( 9 ) == "UseItems:" then
            self.DB[ k ] = nil
        end
    end

    local pack = "UseItems"
    --[[ self.PackInfo[ pack ] = self.PackInfo[ pack ] or {
        items = {}
    } ]]

    for list, lData in pairs( class.itemPack.lists ) do
        for action, data in ipairs( lData ) do
            local scriptID = pack .. ":" .. list .. ":" .. action

            local script = ConvertScript( data, true, scriptID )

            if data.action == "call_action_list" or data.action == "run_action_list" then
                -- Check for Time Sensitive conditions.
                script.TimeSensitive = false

                local lua = script.Lua

                if lua then 
                    -- If resources are checked, it's time-sensitive.
                    for k in pairs( GetResourceInfo() ) do
                        if lua:find( k ) then script.TimeSensitive = true; break end
                    end

                    if lua:find( "rune" ) then script.TimeSensitive = true end

                    if not script.TimeSensitive then
                        -- Check for other time-sensitive variables.
                        if lua:find( "time" ) or lua:find( "cooldown" ) or lua:find( "charge" ) or lua:find( "remain" ) or lua:find( "up" ) or lua:find( "down" ) or lua:find( "ticking" ) or lua:find( "refreshable" ) then
                            script.TimeSensitive = true
                        end
                    end
                end
            end

            local ability

            if data.action then
                ability = class.abilities[ data.action ] or class.specs[ 0 ].abilities[ data.action ]
            end

            if ability then
                if ability.channeled then
                    if not self.Channels[ pack ] then self.Channels[ pack ] = {} end
                    if not self.Channels[ pack ][ data.action ] then 
                        self.Channels[ pack ][ data.action ] = {}
                    end

                    local cInfo = self.Channels[ pack ][ data.action ]

                    -- This will load the channel criteria for the first entry for this ability in any of the action lists.
                    -- This seems OK as long as channel breakage criteria is based on the same logic for the same spell.
                    -- There's genuinely no way to know if a person is channeling Mind Flay because it was recommended, or just because they felt like it.

                    for k in pairs( channelModifiers ) do
                        if script.Modifiers[ k ] and not cInfo[ k ] then cInfo[ k ] = script.Modifiers[ k ] end
                    end
                end
            end

            self.DB[ scriptID ] = script
        end
    end
end    


function Hekili:LoadItemScripts()
    self.Scripts:LoadItemScripts()
end


function Hekili:LoadScript( pack, list, id )
    local data = self.DB.profile.packs[ pack ].lists[ list ][ id ]
    local scriptID = pack .. ":" .. list .. ":" .. id

    local script = ConvertScript( data, true, scriptID )

    if script.Error then
        Hekili:Error( "Error in " .. scriptID .. " conditions:  " .. script.SimC .. "\n    " .. script.Error )
    end    

    if data.action == "call_action_list" or data.action == "run_action_list" then
        -- Check for Time Sensitive conditions.
        script.TimeSensitive = false

        local lua = script.Lua

        if lua then 
            -- If resources are checked, it's time-sensitive.
            for k in pairs( GetResourceInfo() ) do
                if lua:find( k ) then script.TimeSensitive = true; break end
            end

            if lua:find( "rune" ) then script.TimeSensitive = true end

            if not script.TimeSensitive then
                -- Check for other time-sensitive variables.
                if lua:find( "time" ) or lua:find( "cooldown" ) or lua:find( "charge" ) or lua:find( "remain" ) or lua:find( "up" ) or lua:find( "down" ) or lua:find( "ticking" ) or lua:find( "refreshable" ) then
                    script.TimeSensitive = true
                end
            end
        end
    end
    self.Scripts.DB[ scriptID ] = script
end



function scripts:ImplantDebugData( data )
    local prev = state.this_action
    state.this_action = data.actionName

    if data.hook then
        local s = self.DB[ data.hook ]
        local pack, list, entry = data.hook:match( "^(.-):(.-):(.-)$" )

        data.HookHeader = "Called from " .. pack .. ", " .. list .. ", " .. "#" .. entry .. "."
        data.HookScript = s.SimC
        data.HookElements = data.HookElements or {}

        self:StoreValues( data.HookElements, s )
    end

    if data.script then        
        local s = self.DB[ data.script ]
        data.ActScript = s.SimC
        data.ActElements = data.ActElements or {}
        self:StoreValues( data.ActElements, s )
    end

    state.this_action = prev
end


local key_cache = setmetatable( {}, {
    __index = function( t, k )        
        t[k] = k:gsub( "(%S+)%[(%d+)]", "%1.%2" ):gsub( "(%S+)%['([%a%w_]+)']", "%1.%2" )
        return t[k]
    end
})


local checked = {}

function scripts:GetConditionsAndValues( scriptID, listName, actID )
    if listName and actID then
        scriptID = scriptID .. ":" .. listName .. ":" .. actID
    end

    local script = self.DB[ scriptID ]

    if script and script.SimC and script.SimC ~= "" then        
        local output = script.SimC

        local wasDebugging = Hekili.ActiveDebug
        Hekili.ActiveDebug = false

        if script.Elements then
            wipe( checked )

            for k, v in pairs( script.Elements ) do
                if not checked[ k ] then
                    local key = key_cache[ k ]
                    local success, value = pcall( v, true )

                    -- if emsg then value = emsg end
                    if type( value ) == 'number' then
                        if output == key then
                            output = output .. "[" .. tostring( value ) .. "]"
                        else
                            output = output:gsub( "([^a-z0-9_.[])("..key..")([^a-z0-9_.[])", format( "%%1%%2[%.2f]%%3", value ) )
                            output = output:gsub( "^("..key..")([^a-z0-9_.[])", format( "%%1[%.2f]%%2", value ) )
                            output = output:gsub( "([^a-z0-9_.[])("..key..")$", format( "%%1%%2[%.2f]", value ) )
                        end
                        -- output = output:gsub( "^("..key..")", format( "%%1[%.2f]", value ) )
                    else
                        if output == key then
                            output = output .. "[" .. tostring( value ) .. "]"
                        else
                            output = output:gsub( "([^a-z0-9_.[])("..key..")([^a-z0-9_.[])", format( "%%1%%2[%s]%%3", tostring( value ) ) )
                            output = output:gsub( "^("..key..")([^a-z0-9_.[])", format( "%%1[%s]%%2", tostring( value ) ) )
                            output = output:gsub( "([^a-z0-9_.[])("..key..")$", format( "%%1%%2[%s]", tostring( value ) ) )
                        end
                    end

                    checked[ k ] = true
                end
            end

        end
        
        if wasDebugging then Hekili.ActiveDebug = true end
        return output
    end

    return "NONE"
end


function scripts:GetModifierValues( modifier, scriptID, listName, actID )
    if listName and actID then
        scriptID = scriptID .. ":" .. listName .. ":" .. actID
    end

    local script = self.DB[ scriptID ]

    if script and script.ModSimC[ modifier ] and script.ModSimC[ modifier ].SimC ~= "" then
        local output = script.ModSimC[ modifier ]

        wipe( checked )

        for k, v in pairs( script.ModElements[ modifier ] ) do
            if not checked[ k ] then
                local key = key_cache[ k ]
                local success, value = pcall( v )

                -- if emsg then value = emsg end
                if type( value ) == 'number' then
                    if output == key then
                        output = output .. "[" .. tostring( value ) .. "]"
                    else
                        output = output:gsub( "([^a-z0-9_.[])("..key..")([^a-z0-9_.[])", format( "%%1%%2[%.2f]%%3", value ) )
                        output = output:gsub( "^("..key..")([^a-z0-9_.[])", format( "%%1[%.2f]%%2", value ) )
                        output = output:gsub( "([^a-z0-9_.[])("..key..")$", format( "%%1%%2[%.2f]", value ) )
                    end
                    -- output = output:gsub( "^("..key..")", format( "%%1[%.2f]", value ) )
                else
                    if output == key then
                        output = output .. "[" .. tostring( value ) .. "]"
                    else
                        output = output:gsub( "([^a-z0-9_.[])("..key..")([^a-z0-9_.[])", format( "%%1%%2[%s]%%3", tostring( value ) ) )
                        output = output:gsub( "^("..key..")([^a-z0-9_.[])", format( "%%1[%s]%%2", tostring( value ) ) )
                        output = output:gsub( "([^a-z0-9_.[])("..key..")$", format( "%%1%%2[%s]", tostring( value ) ) )
                    end
                end

                checked[ k ] = true
            end
        end

        return output
    end

    return "NONE"
end

Hekili.dumpKeyCache = key_cache
