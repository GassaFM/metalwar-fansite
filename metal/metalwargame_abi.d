module metalwargame_abi;
import transaction;

struct commander
{
	Name key;
	uint64 metal;
	uint64 xp;
	uint8 lvl;
	uint8 troops_limit;
}

struct destroy
{
	uint64 asset_id;
	Name asset_owner;
}

struct gameunit
{
	uint64 asset_id;
	Name owner;
	int32 template_id;
	uint64 location;
	string name;
	string img;
	string rarity;
	uint8 attack;
	uint8 armor;
	uint8 speed;
	uint16 strength;
	uint16 hp;
	uint16 capacity;
	string type;
	bool armor_piercing;
	uint8 poisoning;
	uint8 fire_radius;
	uint16 x;
	uint16 y;
	uint64 next_availability;
	stuffItem[] stuff;
	uint8 poised_value;
	uint8 poised_cnt;
}

struct locations
{
	uint64 location;
	uint8 type_id;
}

struct monsters
{
	uint64 location;
	uint8 type_id;
	uint64 hp;
	uint8 lvl;
}

struct oredeposits
{
	uint64 location;
	uint8 type_id;
	uint64 amount;
	uint8 lvl;
}

struct pvemine2
{
	uint64 asset_id;
	Name asset_owner;
	uint64 signing_value;
}

struct pveraid2
{
	uint64 asset_id;
	Name asset_owner;
	uint64 signing_value;
}

struct receiverand
{
	uint64 asset_id;
	checksum256 random_value;
}

struct rngunits_table
{
	uint64 asset_id;
	Name owner;
	checksum256 random_value;
	uint64 finalnumber;
}

struct shards
{
	uint64 asset_id;
	Name owner;
	uint8 type_id;
	uint16 amount;
}

struct stuffItem
{
	string type;
	uint16 amount;
	uint8 weight;
}

struct teleports
{
	uint64 location;
	uint8 type_id;
	uint8 price;
}

struct testloc
{
	uint64 location;
	uint8 type_id;
}

struct unstake
{
	Name to;
	uint64[] asset_ids;
}

alias commanderElement = commander;
alias locationsElement = locations;
alias monstersElement = monsters;
alias oredepositsElement = oredeposits;
alias rngunitsElement = rngunits_table;
alias shardsElement = shards;
alias teleportsElement = teleports;
alias testlocElement = testloc;
alias unitsElement = gameunit;
