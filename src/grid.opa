/*
 * OpaPow4
 *
 * @author Matthieu Guffroy
 */

/*
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

package mattgu74.pow4

type Grid.msg = { txt : string } / 
                { error : string } / 
                { play : Game.action ; 
                  color : {blue} / {red} / {debut} / {fin} } // debut and fin should not be used

Grid = {{

  room = Network.cloud("room") : Network.network((Grid.msg, string))

  broadcast(msg, player)= Network.broadcast((msg, player), room)

  @client receive((msg, player)) =
    if player == Option.get(Player.get()).name then
      match msg with
       | {txt = t } -> jlog(t)
       | {error = t} -> jlog("Error : {t}")
       | ~{ play; color } -> animate(play.push, 0, color)
       | _ -> jlog("unknown message")
    else
      void

  @client empty(nbcol, nbline)=
    line(line)=List.init((i -> <td class="case" id="{line}_{i}" 
                                   onmouseover={_ -> Dom.set_class(Dom.select_id("b_{i}"), "rollover")}
                                   onmouseout={_ -> Dom.set_class(Dom.select_id("b_{i}"), "selecteur")}
                                   onclick={_ -> click(i)} ></> ), nbcol)
    table=List.init((i -> <tr>{line(i)}</tr> ), nbline)
    selecteur=List.init((i -> <input type="button" id="b_{i}" class="selecteur"/>), nbcol)
    <>{List.fold((v,a -> <>{a}</><>{v}</>), selecteur, <></>)}</><table>{List.fold((v,a -> <>{a}</><>{v}</>), table, <></>)}</table>

  init()=
    do Network.add_callback(receive, room)
    Game.add(Option.get(Player.get()).name)

  click(col)= 
    do Game.click(Option.get(Player.get()).name, col)
    void

  @client animate(col, line, c)=
    color = match c with
             | {blue} -> "casebleue"
             | {red} -> "caserouge"
             | _ -> "case" // should not be here, but if he does, then but a white case
    do if line != 0 then
      Dom.set_class(Dom.select_id("{line-1}_{col}"), "case")
    do Dom.set_class(Dom.select_id("{line}_{col}"), color)
    if Dom.has_class(Dom.select_id("{line+1}_{col}"),"case") then
      Scheduler.sleep(100, ( -> animate(col, line+1, c)))
    else
      void

}}
