LibItemBuffs-1.0
================

Buff-to-item database.

[![Build status](https://travis-ci.org/AdiAddons/LibItemBuffs-1.0.svg?branch=master)](https://travis-ci.org/AdiAddons/LibItemBuffs-1.0)

LibItemBuffs-1.0 allows to retrieve the identifier or slot of an item that provides a buff.

It has data for the following items and enchantments:

  * MoP high-level enchantments from enchanting, tailoring and engineering.
  * MoP legendary meta-gems.
  * All trinkets, both "Equip" procs and "Use" effects.
  * All consumables of the following categories: potions, elixirs, flasks, scrolls, foods & drinks and other.

The former two lists are maintained by the author. The latter two ones are automatically built using an HTML parser.

## Embedding LibItemBuffs-1.0

### Manually

Just copy the whole package somewhere in your addon and reference the file LibItemBuffs-1.0.xml in your TOC file.

### Using the wowace packager

Add the following lines into your .pkgmeta:

```
externals:
  libs/LibItemBuffs-1.0:
    url: git://github.com/AdiAddons/LibItemBuffs-1.0.git
    tag: latest
```

And these in your TOC file:

```
libs\LibItemBuffs-1.0\LibItemBuffs-1.0.xml
```

## Using LibItemBuffs-1.0

See the API page (todo).

## License

LibItemBuffs-1.0 is licensed using the GPL v3.
