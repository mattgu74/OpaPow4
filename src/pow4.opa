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
import components.chat

@server default_chat = CChat.init(CChat.default_config(Random.string(8)))

type Pow4.conf = {
  nbcol : int;     
  nbline : int;  
  player1 : Player.player;
  player2 : Player.player;
}

type Pow4.message = {ping}

Pow4 = {{

  @client
  ping(f) =
    Scheduler.timer(15000, ( ->_ = f()
                                void))

  conf = { col = 7 ; line = 10 }

  init(player : Player.player) =    
    do Session.send(Player.players, {add = player.name})                    
    do Dom.transform([#afficheur <- <>Connexion réussi <strong>{player.name}</strong>!</>])
    do Dom.set_class(#afficheur, "afficheur_success")
    do Scheduler.timer(10000, Player.scoreboard) 
    do Scheduler.sleep(100, Player.scoreboard)
    do ping( -> Player.ping(player.name))    
    do Scheduler.sleep(100, ( -> Grid.init(conf.col, conf.line)) )
    chat=
      id = Random.string(8)
      config = CChat.default_config(id)
      initial_content = default_chat.requester({ range = (0, config.history_limit) })
      initial_display = {CChat.default_display(id, player.name) with reverse=false}
      CChat.create(config, default_chat, id, initial_display, initial_content, ignore)
    <div id=#chat>
        <h4>Chat</h4>
        {chat}
    </div>
    <div id=#gamefield />
    <div id=#scoreboard />

}}
