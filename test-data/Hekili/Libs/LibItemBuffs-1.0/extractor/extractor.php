<?php
/*
AdiRareLocations extractor - Extract locations of rare mobs from wowhead.com.
Copyright (C) 2013 Adirelle (adirelle@gmail.com)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

require_once('vendor/autoload.php');

use Symfony\Component\DomCrawler\Crawler;
use Symfony\Component\CssSelector\CssSelector;

define('SITE_ROOT', 'https://www.wowhead.com');

function fetchPage($path) {
	$path = ltrim($path, '/');
	$cacheFile = "cache/".preg_replace('/\W/', '_', $path);
	if(file_exists($cacheFile)) {
		return file_get_contents($cacheFile);
	} else {
		$ctx = stream_context_create(
			['http' => ['header'=> "User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64; rv:32.0) Gecko/20100101 Firefox/32.0\r\n" ]]
		);
		$content = file_get_contents(SITE_ROOT.'/'.$path, false, $ctx);
		if($content !== FALSE) {
			if(!is_dir("cache")) mkdir("cache");
			file_put_contents($cacheFile, $content);
		}

		return $content;
	}
}

function fetchTooltip($uri) {
	$js = fetchPage($uri.'&power');
	$escapedJs = str_replace('\"', '%QUOTE%', $js);
	$values = array();
	if(preg_match_all('/"(\w+)":\s*"(.*)"/U', $escapedJs, $matches, PREG_SET_ORDER)) {
		foreach($matches as $groups) {
			$values[$groups[1]] = str_replace('%QUOTE%', '\"', $groups[2]);
		}
	}

	return $values;
}

echo "Fetching trinket list:\n";
$crawler = new Crawler();
$crawler->addContent(fetchPage('/trinkets'));
$scripts = $crawler->filter('script[type="text/javascript"]')->extract('_text');
$trinkets = array();
foreach($scripts as $script) {
	if(strpos($script, 'listviewitems') !== FALSE) {
		if(preg_match_all('/"id":(\d+)/', $script, $matches, PREG_SET_ORDER)) {;
			foreach($matches as $groups) {
				$trinkets[intval($groups[1])] = 'trinkets';
				echo '.';
			}
		} else {
			echo 'x';
		}
	}
}
echo "\nDone\n".count($trinkets)." trinkets found\n\n";

$categories = array(
	"potions" => '/potions',
	"elixirs" => '/elixirs',
	"flasks" => '/flasks',
	"scrolls" => '/scrolls',
	"food & drinks" => '/food-and-drinks',
	"other consumables" => '/other-consumables',
	"bandages" => '/bandages',
	"miscellaneous items" => '/miscellaneous-items?filter=161:62;1:1;0:2', // available to players and with CD > 2 secs
);
$consumables = array();

foreach($categories as $cat => $param) {
	echo "Fetching $cat list:\n";
	$crawler = new Crawler();
	$crawler->addContent(fetchPage($param));
	$scripts = $crawler->filter('script[type="text/javascript"]')->extract('_text');
	$n = 0;
	foreach($scripts as $script) {
		if(strpos($script, 'listviewitems ') !== FALSE) {
			if(preg_match_all('/"id":(\d+)/', $script, $matches, PREG_SET_ORDER)) {;
				foreach($matches as $groups) {
					$consumables[intval($groups[1])] = 'consumables';
					echo '.';
					$n++;
				}
			} else {
				echo 'x';
			}
		}
	}
	echo "\nDone\n$n ${cat} found\n\n";
}

$allItems = $trinkets;
foreach($consumables as $id => $kind) {
	$allItems[$id] = $kind;
}

$equipSpells = array();
$spells = array();
$itemNames = array();

echo "Scanning ".count($allItems)." item tooltips:\n";
foreach($allItems as $itemID => $kind) {
	$attrs = fetchTooltip("/item=$itemID");
	if(!empty($attrs['name_enus']) && !empty($attrs['tooltip_enus'])) {
		$itemNames[$itemID] = str_replace('\"', '"', $attrs['name_enus']);
		if(preg_match_all('/(Use|Equip):.+spell=(\d+)/', $attrs['tooltip_enus'], $matches, PREG_SET_ORDER)) {
			foreach($matches as $match) {
				list(, $type, $spellID) = $match;
				$spellID = intval($match[2]);
				if($match[1] == 'Use') {
					$spells[$spellID][] = $itemID;
				} else {
					$equipSpells[$spellID][] = $itemID;
				}
				echo '.';
			}
		} else {
			echo 'x';
		}
	} else {
		echo 'E';
	}
}
printf("\nDone\nFound %d equip effects and %d use effects.\n\n", count($equipSpells),  count($spells));

echo "Scanning ".count($equipSpells)." equip effects:\n";
$numBuffs = 0;
foreach($equipSpells as $spellID => $itemIDs) {
	$page = fetchPage("/spell=".$spellID);
	if(preg_match_all('/g_spells\.createIcon\((\d+),/', $page, $matches)) {
		foreach($matches[1] as $buffID) {
			echo '.';
			$spells[$buffID] = $itemIDs;
			$numBuffs++;
		}
	} else {
		echo 'x';
	}
}
echo "\nDone\n$numBuffs more spells found.\n\n";

$buffs = array(
	'consumables' => array(),
	'trinkets' => array(),
);
$spellNames = array();

echo "Scanning ".count($spells)." spell tooltips:\n";
foreach($spells as $spellID => $itemIDs) {
	$tooltip = fetchTooltip("/spell=$spellID");
	if(!empty($tooltip)) {
		if(!empty($tooltip['buff_enus'])) {
			$name = str_replace('\"', '"', $tooltip['name_enus']);
			// Ignore food and drink buffs
			if(!preg_match('/^((Bountiful )?Food|Refresh|(Holiday )?Drink)/i', $name)) {
				$spellNames[$spellID] = $name;
				$kind = $allItems[$itemIDs[0]];
				$buffs[$kind][$spellID] = $itemIDs;
			} else {
				echo '-';
			}
			echo '.';
		} else {
			echo '-';
		}
	} else {
		echo 'x';
	}
}
$allCount = count($buffs['consumables']) + count($buffs['trinkets']);
echo "\n".$allCount." buffs found.\n\n";

$code = array(
	'--== CUT HERE ==--',
	'version = '.date("YmdHis")
);

function sortInts($a, $b) {
	return intval($a) - intval($b);
}

foreach(array('trinkets', 'consumables') as $cat) {
	$code[] = "-- ".ucfirst($cat);
	uksort($buffs[$cat], "sortInts");
	foreach($buffs[$cat] as $spell => $items) {
		if(count($items) == 1) {
			$item = $items[0];
			$name = $spellNames[$spell];
			if($itemNames[$item] != $name) {
				$name .= " (".$itemNames[$item].")";
			}
			$code[] = sprintf("%s[%6d] = %6d -- %s", $cat, $spell, $item, $name);
		} else {
			$code[] = sprintf("%s[%6d] = { -- %s", $cat, $spell, $spellNames[$spell]);
			usort($items, "sortInts");
			foreach($items as $item) {
				$code[] = sprintf("\t%6d, -- %s", $item, $itemNames[$item]);
			}
			$code[] = '}';
		}
	}
}
$code[] = "";
$code[] = "LibStub('LibItemBuffs-1.0'):__UpgradeDatabase(version, trinkets, consumables, enchantments)";

$filename = "LibItemBuffs-Database-1.0.lua";
$lib = file_get_contents("../$filename");
$pos = strpos($lib, '--== CUT HERE ==--');
file_put_contents("../$filename", substr($lib, 0, $pos).join("\n", $code)."\n");
