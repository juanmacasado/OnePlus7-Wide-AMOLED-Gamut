#!/system/bin/sh
# SPDX-FileCopyrightText: 2026 juanmacasado
# SPDX-License-Identifier: GPL-3.0-or-later
# Read-only contract helpers used by customize.sh. No service restarts/setters.
parse_parcel() {
  awk -v operation="$1" -v allow_five="${2:-false}" -f "$MODPATH/parcel.awk"
}
interface_ready() {
  timeout 10 service check "$1" 2>/dev/null | grep -q ': found$'
}
interface_version() {
  timeout 10 service call "$1" 16777215 2>/dev/null | parse_parcel version
}
interface_hash() {
  timeout 10 service call "$1" 16777214 2>/dev/null | parse_parcel hash
}
standard_interface_set() {
  # An extra LiveDisplay interface could be lost by replacing the complete HAL.
  awk '
    /vendor[.]lineage[.]livedisplay[.]/ {
      name=$2;sub(/:$/, "", name)
      count++
      sub(/^vendor[.]lineage[.]livedisplay[.]/, "", name)
      if(name!="IDisplayModes/default" && name!="IAntiFlicker/default" &&
         name!="IPictureAdjustment/default" && name!="ISunlightEnhancement/default") bad=1
    }
    END {exit bad || count!=4}
  '
}
panel_contract() {
  # These are Qualcomm QDCM panel modes, not framework ColorMode enums.
  awk '
    /^[[:space:]]*Available Color Modes:[[:space:]]*$/ {
      inside=1;a=0;b=0;c=0;d=0;next
    }
    inside && $2~/^[0-9]+$/ {
      if($1=="zhal_native" && $2==0) a=1
      if($1=="SRGB" && $2==1) b=1
      if($1=="advance_native" && $2==2) c=1
      if($1=="advance_p3" && $2==4) d=1
      if(a&&b&&c&&d) found=1
      next
    }
    {inside=0}
    END {exit !found}
  '
}
