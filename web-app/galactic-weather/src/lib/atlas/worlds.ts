import type { Climate, World, WorldId } from "./types";

/**
 * The catalog of worlds available to assign to a weather slot.
 *
 * `id` must match the filename in /public/planets/<id>.png. Descriptions here
 * are the world's canonical copy — used whenever a world is assigned to a slot
 * that has no slot-specific description of its own (see slots.ts).
 */
export const WORLDS: readonly World[] = [
	{
		id: "ahch-to",
		name: "Ahch-To",
		description: "A remote ocean world of jagged island peaks, sea spray, and restless grey water.",
		climate: "ocean",
		color: { primary: "#5C7684", headline: "#B4CEDA" },
		isPremium: true,
	},
	{
		id: "alderaan",
		name: "Alderaan",
		description: "A peaceful, beautiful world of rolling hills and crisp, clear air.",
		climate: "temperate",
		color: { primary: "#5F749E", headline: "#C4D8E8" },
		isPremium: true,
	},
	{
		id: "at-attin",
		name: "At-Attin",
		description: "A rumored paradise world — warm and hazy beneath a blanket of soft clouds.",
		climate: "temperate",
		color: { primary: "#7A9E8A", headline: "#C8E0D0" },
	},
	{
		id: "bespin",
		name: "Bespin",
		description: "Cloud City drifts through cold upper atmosphere, wrapped in dense cloud cover.",
		climate: "sky",
		color: { primary: "#C15A51", headline: "#F4BE9C" },
	},
	{
		id: "corellia",
		name: "Corellia",
		description: "A shipyard world of green industrial haze, its cranes fading into the murk.",
		climate: "urban",
		color: { primary: "#3E6B57", headline: "#C3D68F" },
		isPremium: true,
	},
	{
		id: "coruscant",
		name: "Coruscant",
		description: "A city that covers a world entirely — endless towers under a haze of traffic light.",
		climate: "urban",
		color: { primary: "#6E7A93", headline: "#C3CEE4" },
		isPremium: true,
	},
	{
		id: "dagobah",
		name: "Dagobah",
		description: "A swampy, mist-laden world with a damp atmosphere that matches steady light rain.",
		climate: "forest",
		color: { primary: "#48542D", headline: "#6C7858" },
	},
	{
		id: "daiyu",
		name: "Daiyu",
		description: "A neon port city under low cloud, its streets slick with cold rain.",
		climate: "urban",
		color: { primary: "#14403C", headline: "#63C7BC" },
	},
	{
		id: "dantooine",
		name: "Dantooine",
		description: "Quiet farmland under tall white clouds — green, cool, and open to the horizon.",
		climate: "temperate",
		color: { primary: "#2F8272", headline: "#D8E39B" },
	},
	{
		id: "endor",
		name: "Endor",
		description: "A forest moon with cool, humid air and frequent mist through dense woodland.",
		climate: "forest",
		color: { primary: "#6B8A60", headline: "#BCD2B5" },
	},
	{
		id: "exegol",
		name: "Exegol",
		description: "A storm-wracked world with relentless lightning, heavy rain, and violent weather.",
		climate: "storm",
		color: { primary: "#9589A4", headline: "#686788" },
	},
	{
		id: "ferrix",
		name: "Ferrix",
		description: "A close-built foundry town where terracotta roofs hold the last of the sun.",
		climate: "urban",
		color: { primary: "#B5622F", headline: "#F6CE93" },
		isPremium: true,
	},
	{
		id: "ghorman",
		name: "Ghorman",
		description: "A temperate trade world of grey overcast skies and quiet, cultural streets.",
		climate: "urban",
		color: { primary: "#7A8090", headline: "#B8C0C8" },
	},
	{
		id: "hoth",
		name: "Hoth",
		description: "An icy world covered in snow year-round, swept by freezing wind.",
		climate: "ice",
		color: { primary: "#39657F", headline: "#6DB3DC" },
	},
	{
		id: "ilum",
		name: "Ilum",
		description: "A frigid, crystal-lined world with clear skies and severe cold.",
		climate: "ice",
		color: { primary: "#A4B3C1", headline: "#A9CEEF" },
		isPremium: true,
	},
	{
		id: "jakku",
		name: "Jakku",
		description: "A desert scrapyard world with endless dunes and dust-choked skies.",
		climate: "desert",
		color: { primary: "#A8895A", headline: "#E8D09A" },
		isPremium: true,
	},
	{
		id: "kamino",
		name: "Kamino",
		description: "A water planet that experiences frequent, heavy rainfall.",
		climate: "ocean",
		color: { primary: "#868D9F", headline: "#C9CFB9" },
	},
	{
		id: "kashyyyk",
		name: "Kashyyyk",
		description: "A forested world that feels brisk and chilly beneath towering canopies.",
		climate: "forest",
		color: { primary: "#6C7F74", headline: "#7C9688" },
	},
	{
		id: "kijimi",
		name: "Kijimi",
		description: "A cold mountain world with ancient cities dusted in light snowfall.",
		climate: "ice",
		color: { primary: "#8AA3B5", headline: "#C8DDE8" },
	},
	{
		id: "lothal",
		name: "Lothal",
		description: "Wide grass plains beneath an enormous, cloudless sky.",
		climate: "temperate",
		color: { primary: "#2C7FA6", headline: "#FBDD97" },
		isPremium: true,
	},
	{
		id: "mortis",
		name: "Mortis",
		description: "A realm between worlds, shrouded in thick fog and an otherworldly stillness.",
		climate: "storm",
		color: { primary: "#7A7090", headline: "#B0A8C8" },
		isPremium: true,
	},
	{
		id: "mustafar",
		name: "Mustafar",
		description: "A volcanic world of lava rivers and an ash-filled, smoky sky.",
		climate: "volcanic",
		color: { primary: "#AC5861", headline: "#B47A80" },
	},
	{
		id: "naboo",
		name: "Naboo",
		description: "A balanced, temperate climate with clear skies and calm conditions.",
		climate: "temperate",
		color: { primary: "#7A609B", headline: "#B5C0EE" },
	},
	{
		id: "niamos",
		name: "Niamos",
		description: "A sunny, tropical beach planet known for its vibrant resorts and relaxing atmosphere.",
		climate: "ocean",
		color: { primary: "#7B9684", headline: "#DBDFBF" },
	},
	{
		id: "nur",
		name: "Nur",
		description: "A dark ocean moon of perpetual rain, lashed by wind above a black sea.",
		climate: "ocean",
		color: { primary: "#4A5A6B", headline: "#9DB2C4" },
		isPremium: true,
	},
	{
		id: "scarif",
		name: "Scarif",
		description: "A warm tropical world with clear skies and bright coastal weather.",
		climate: "ocean",
		color: { primary: "#237691", headline: "#95E1F6" },
	},
	{
		id: "tatooine",
		name: "Tatooine",
		description: "A desert world of twin suns, known for its scorching heat and clear skies.",
		climate: "desert",
		color: { primary: "#944505", headline: "#FDC683" },
	},
	{
		id: "yavin",
		name: "Yavin 4",
		description: "A jungle moon draped in warm humidity and overcast tropical skies.",
		climate: "forest",
		color: { primary: "#6B7A4A", headline: "#B8C890" },
	},
] as const;

export const CLIMATE_LABELS: Record<Climate, string> = {
	desert: "Desert",
	ice: "Ice",
	ocean: "Ocean",
	forest: "Forest",
	volcanic: "Volcanic",
	urban: "Urban",
	temperate: "Temperate",
	storm: "Storm",
	sky: "Sky",
};

/**
 * Fixed display order for biomes, the same way SLOT_GROUP_ORDER fixes the
 * order of slot groups. Roughly hospitable -> hostile, so the Passport reads
 * as a journey outward rather than an alphabetical list.
 */
export const CLIMATE_ORDER: readonly Climate[] = [
	"temperate",
	"forest",
	"ocean",
	"desert",
	"ice",
	"volcanic",
	"storm",
	"sky",
	"urban",
];

const WORLD_BY_ID = new Map<WorldId, World>(WORLDS.map((w) => [w.id, w]));

export const getWorld = (id: WorldId): World | undefined => WORLD_BY_ID.get(id);

export const isKnownWorld = (id: string): id is WorldId => WORLD_BY_ID.has(id);
