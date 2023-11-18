#!/command/with-contenv bash
# shellcheck shell=bash disable=SC1091

# get data from kx1t's prometheus instance related to the Belmont geiger counter
#---------------------------------------------------------------------------------------------
# Copyright (C) 2023, Ramon F. Kolb (kx1t)
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation, version 3 of the License.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program.
# If not, see <https://www.gnu.org/licenses/>.
#---------------------------------------------------------------------------------------------

TELEM_PROM_URL=http://192.168.0.29:9090
TELEM_PROM_QUERY='geiger_usvh{job="geiger-bos"}'
TELEM_JQ_FILTER='.data.result[0].value[]'

readarray -t x < <(curl -gsSL "$TELEM_PROM_URL/api/v1/query?query=$TELEM_PROM_QUERY" |jq -r "$TELEM_JQ_FILTER")
time="${x[0]%%.*}"
value="$(bc -l <<< "scale=0; ${x[1]}*1000 / 1")"

echo "$time $value"