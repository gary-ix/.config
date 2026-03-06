#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Zoom All Windows
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🪟
# @raycast.packageName Window Tools

# Fill all visible standard windows via each app's Window menu.
if ! osascript -e 'tell application "System Events" to tell process "Finder" to count windows' >/dev/null 2>&1; then
  osascript -e 'display notification "Grant Raycast access in Privacy & Security > Accessibility, then run again." with title "Zoom All Windows"' >/dev/null 2>&1
  exit 1
fi

actions=$(osascript 2>/dev/null <<'APPLESCRIPT'
set actionCount to 0

tell application "System Events"
    set procs to (application processes whose background only is false and visible is true)

    repeat with p in procs
        set ws to {}
        try
            set ws to windows of p
        end try

        repeat with w in ws
            set shouldHandle to true

            try
                if (value of attribute "AXMinimized" of w) is true then set shouldHandle to false
            end try

            try
                set subroleValue to value of attribute "AXSubrole" of w
                if subroleValue is not missing value and subroleValue is not "AXStandardWindow" then set shouldHandle to false
            end try

            if shouldHandle is true then
                try
                    set frontmost of p to true
                end try
                try
                    perform action "AXRaise" of w
                end try
                try
                    set value of attribute "AXMain" of w to true
                end try
                try
                    set value of attribute "AXFocused" of w to true
                end try
                delay 0.14

                set didClickMenu to false

                try
                    tell p
                        if exists menu bar item "Window" of menu bar 1 then
                            set fillItems to {}
                            try
                                set fillItems to (menu items of menu "Window" of menu bar item "Window" of menu bar 1 whose enabled is true and name starts with "Fill")
                            end try

                            if (count of fillItems) > 0 then
                                click item 1 of fillItems
                                set didClickMenu to true
                            else
                                set zoomItems to {}
                                try
                                    set zoomItems to (menu items of menu "Window" of menu bar item "Window" of menu bar 1 whose enabled is true and name is "Zoom")
                                end try
                                if (count of zoomItems) > 0 then
                                    click item 1 of zoomItems
                                    set didClickMenu to true
                                end if
                            end if
                        end if
                    end tell
                end try

                if didClickMenu is true then
                    set actionCount to actionCount + 1
                else
                    try
                        perform action "AXZoomWindow" of w
                        set actionCount to actionCount + 1
                    on error
                        try
                            click (first button of w whose subrole is "AXZoomButton")
                            set actionCount to actionCount + 1
                        end try
                    end try
                end if

                delay 0.05
            end if
        end repeat
    end repeat
end tell

return actionCount
APPLESCRIPT
)

if [ $? -ne 0 ]; then
  osascript -e 'display notification "Window automation failed while running menu actions." with title "Zoom All Windows"' >/dev/null 2>&1
  exit 1
fi

if ! [ "${actions:-0}" -gt 0 ] 2>/dev/null; then
  osascript -e 'display notification "No Fill/Zoom actions were available for current windows." with title "Zoom All Windows"' >/dev/null 2>&1
fi

exit 0
