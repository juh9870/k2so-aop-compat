---@class ItemReplacement
---@field name? string
---@field type? ("item"|"fluid")
---@field amountMult? number
---@field delete? boolean

---@alias ItemReplacementMap {[string]: ItemReplacement}

---This function patches the recipe to replace inputs and outputs with
---different items or fluids
---
---Item/Fluid amount will not go below 1
---@param recipe data.RecipePrototype|data.RecipeID
---@param replacements ItemReplacementMap
local function patchRecipe(recipe, replacements)
	if type(recipe) == "string" then
		recipe = data.raw["recipe"][recipe]
	end
	if recipe.ingredients then
		for idx = #recipe.ingredients, 1, -1 do
			local ing = recipe.ingredients[idx]
			local newIng = replacements[ing.name]
			if newIng then
				if newIng.delete then
					table.remove(recipe.ingredients, idx)
				else
					if newIng.type then
						ing.type = newIng.type
					end
					if newIng.name then
						ing.name = newIng.name
					end
					if newIng.amountMult then
						ing.amount = math.max(1, math.floor(ing.amount * newIng.amountMult + 0.5))
					end
					recipe.ingredients[idx] = ing
				end
			end
		end
	end
	if recipe.results then
		for idx = #recipe.results, 1, -1 do
			local prod = recipe.results[idx]
			local newProd = replacements[prod.name]
			if replacements[prod.name] then
				if newProd.delete then
					table.remove(recipe.results, idx)
				else
					if newProd.type then
						prod.type = newProd.type
					end
					if newProd.name then
						prod.name = newProd.name
					end
					if newProd.amountMult then
						prod.amount = math.max(1, math.floor(prod.amount * newProd.amountMult))
					end
					recipe.results[idx] = prod
				end
			end
		end
	end
	if recipe.main_product and replacements[recipe.main_product] then
		recipe.main_product = replacements[recipe.main_product].name
	end
end

---This function patches the list of recipes to replace inputs and outputs with
---different items or fluids
---
---Item/Fluid amount will not go below 1
---@param recipes (data.RecipePrototype|data.RecipeID)[]
---@param replacements ItemReplacementMap
local function patchRecipes(recipes, replacements)
	for _, recipe in ipairs(recipes) do
		patchRecipe(recipe, replacements)
	end
end

---Sets icons for the item/recipe/whatever
---@param proto any
---@param icons (data.IconData)[]
local function setIcons(proto, icons)
	proto.icon = nil
	proto.icons = icons
end

-- ========================================
-- === remove some machines and recipes ===
-- ========================================

local yeet = {
	["aop-quantum-assembler"] = true,
	["aop-quantum-stabilizer"] = true,
	["aop-quantum-computer"] = true,
	["aop-quantum-machinery"] = true,
	["aop-biochemical-facility"] = true,
	["aop-advanced-assembling-machine"] = true,
	["aop-automation-4"] = true,

	-- K2 adds its own recipes for these
	["aop-tree-planting"] = true,
	["aop-yumako-planting"] = true,
	["aop-jellynut-planting"] = true,
}

local yeet_categories = {
	"item",
	"assembling-machine",
	"furnace",
	"lab",
	"beacon",
	"technology",
	"recipe",
}
for _, tech in pairs(data.raw["technology"]) do
	if tech.effects then
		for i = #tech.effects, 1, -1 do
			local effect = tech.effects[i]
			if effect.type == "unlock-recipe" then
				if yeet[effect.recipe] then
					table.remove(tech.effects, i)
				end
			end
		end
	end
end

for id, _ in pairs(yeet) do
	for _, cat in ipairs(yeet_categories) do
		local entry = data.raw[cat][id]
		if entry then
			entry.enabled = false
			entry.hidden = true
		end
	end
end

-- move biochemical recipes to biochamber
table.insert(data.raw["assembling-machine"]["biochamber"].crafting_categories, "biochemistry")

-- =====================
-- === recipe tweaks ===
-- =====================

-- Switch aop greenhouse to be just an upgrade to K2 greenhouse
data.raw["assembling-machine"]["aop-greenhouse"].crafting_categories =
	data.raw["assembling-machine"]["kr-greenhouse"].crafting_categories

-- Switch agricultural productivity tech to buff kr recipes
local wood_prod_tech = data.raw["technology"]["aop-agriculture-productivity"]
wood_prod_tech.effects = {}

for _, recipe in ipairs({ "kr-wood-with-fertilizer", "wood", "kr-jellynut", "kr-yumako" }) do
	table.insert(wood_prod_tech.effects, {
		type = "change-recipe-productivity",
		recipe = recipe,
		change = 0.1,
	})
end

-- Molten metals inline with k2 balance
patchRecipes({ "aop-direct-molten-copper", "aop-direct-molten-iron" }, {
	["molten-copper"] = { amountMult = 600 / 750 },
	["molten-iron"] = { amountMult = 600 / 750 },
})

-- Reduce arc furnace prod
data.raw["assembling-machine"]["aop-arc-furnace"].effect_receiver.base_effect.productivity = 0.25

-- Switch advanced furnace from 3 foundries to 1 foundry + 2 arc furnaces
patchRecipe("kr-advanced-furnace", { ["foundry"] = { amountMult = 1 / 3 } })

table.insert(
	data.raw["recipe"]["kr-advanced-furnace"].ingredients,
	{ type = "item", name = "aop-arc-furnace", amount = 2 }
)

table.insert(data.raw["technology"]["kr-advanced-furnace"].prerequisites, "aop-arc-furnace")

-- ============================
-- === specialized sciences ===
-- ============================

patchRecipes({
	"aop-military-specialized-metallurgic-science-pack",
	"aop-hydraulics-specialized-cryogenic-science-pack",
	"aop-petrochemistry-specialized-electromagnetic-science-pack",
	"aop-hybridation-specialized-agricultural-science-pack",
}, {
	["metallurgic-science-pack"] = { name = "kr-metallurgic-research-data" },
	["cryogenic-science-pack"] = { name = "kr-cryogenic-research-data" },
	["electromagnetic-science-pack"] = { name = "kr-electromagnetic-research-data" },
	["agricultural-science-pack"] = { name = "kr-agricultural-research-data" },
})

setIcons(data.raw["recipe"]["aop-military-specialized-metallurgic-science-pack"], {
	{
		icon = "__k2so-assets__/icons/cards/metallurgic-research-data.png",
		icon_size = 64,
		scale = 0.65,
		shift = { 2, -2 },
	},
	{
		icon = "__Age-of-Production-Graphics__/graphics/icons/explosive-core.png",
		scale = 0.45,
		icon_size = 64,
		shift = { -11, 11 },
	},
})

setIcons(data.raw["recipe"]["aop-hydraulics-specialized-cryogenic-science-pack"], {
	{
		icon = "__k2so-assets__/icons/cards/cryogenic-research-data.png",
		icon_size = 64,
		scale = 0.65,
		shift = { 2, -2 },
	},
	{
		icon = "__Age-of-Production-Graphics__/graphics/icons/lithium-fluoride.png",
		icon_size = 64,
		scale = 0.45,
		shift = { -11, 11 },
	},
})

setIcons(data.raw["recipe"]["aop-petrochemistry-specialized-electromagnetic-science-pack"], {
	{
		icon = "__k2so-assets__/icons/cards/electromagnetic-research-data.png",
		icon_size = 64,
		scale = 0.65,
		shift = { 2, -2 },
	},
	{
		icon = "__Age-of-Production-Graphics__/graphics/icons/magnetic-flow-meter.png",
		icon_size = 64,
		scale = 0.45,
		shift = { -11, 11 },
	},
})

setIcons(data.raw["recipe"]["aop-hybridation-specialized-agricultural-science-pack"], {
	{
		icon = "__k2so-assets__/icons/cards/agricultural-research-data.png",
		icon_size = 64,
		scale = 0.65,
		shift = { 2, -2 },
	},
	{
		icon = "__Age-of-Production-Graphics__/graphics/icons/hybrid-bacteria-1.png",
		icon_size = 64,
		scale = 0.45,
		shift = { -11, 11 },
	},
})

-- ============================
-- === air scrubbing tweaks ===
-- ============================

local speed_mult = 4
local target_time = 480 / speed_mult
local function patch_scrubbing(id)
	local recipe = data.raw["recipe"][id]

	if not recipe then
		log("recipe `" .. id .. "` is not present")
		return
	end

	if id:sub(1, 4) ~= "aop-" then
		log("recipe name `" .. recipe.name .. "` doesn't start with aop-")
	end
	if id:sub(-14) ~= "-air-scrubbing" then
		log("recipe name `" .. recipe.name .. "` doesn't end with -air-scrubbing")
	end

	log("patching recipe " .. recipe.name)
	local mult = target_time / recipe.energy_required
	recipe.energy_required = target_time
	if not recipe.ingredients then
		recipe.ingredients = {}
	end
	if not recipe.results then
		recipe.results = {}
	end
	for i = #recipe.ingredients, 1, -1 do
		local value = recipe.ingredients[i]
		value.amount = value.amount * mult / 2
		if value.name == "water" then
			table.remove(recipe.ingredients, i)
		end
	end
	for i = #recipe.results, 1, -1 do
		local value = recipe.results[i]
		if value.name == "water" then
			table.remove(recipe.results, i)
		else
			if value.probability and value.probability ~= 1 then
				-- collapse probabilities
				value.amount = value.amount * value.probability * mult + 0.5
				value.probability = 1
			else
				value.amount = value.amount * mult
			end
			if value.amount < 1 then
				value.probability = value.amount
				value.amount = 1
			end
			value.amount = math.floor(value.amount + 0.5)
		end
	end
	table.insert(recipe.ingredients, {
		type = "item",
		name = "kr-pollution-filter",
		amount = 1,
	})
	table.insert(recipe.results, {
		type = "item",
		name = "kr-used-pollution-filter",
		amount = 1,
		probability = 0.9,
	})
end

for id, _ in pairs(data.raw["recipe"]) do
	if id:sub(1, 4) == "aop-" and id:sub(-14) == "-air-scrubbing" then
		patch_scrubbing(id)
	end
end

local scrubber = data.raw["assembling-machine"]["aop-scrubber"]
for kind, emission in pairs(scrubber.energy_source.emissions_per_minute) do
	scrubber.energy_source.emissions_per_minute[kind] = emission * speed_mult * 1.25
end
