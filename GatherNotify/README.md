# GatherNotify

Required Mining, Herbalism, and Skinning on world herb, vein, and skin tooltips for WoW Forever, plus a chat line when a node rank unlocks.

Version 1.8.3. Slash: `/gn`, `/gathernotify`, `/gnotify`.

## TooltipKit

Kind checks and the tooltip pass live in TooltipKit. This addon loads it first when both are enabled.

https://github.com/SultonMRP/TooltipKit

`## OptionalDeps: TooltipKit` is set in `GatherNotify.toc` and `GatherNotify_Camelot.toc`. GatherNotify still runs if TooltipKit is disabled. With the library on, a bag item that shares a node name (Peacebloom) is left alone. World nodes still get the require line before the tooltip is shown.

## Install

Unzip `GatherNotify` into `Interface\AddOns`. Enable GatherNotify and TooltipKit, then reload.
