/*
 * Player module
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

import stdlib.crypto

type Player.player = {
  name : string ;
  pwd : string ;
  rank : int ;
  online : { true } / { false } ;
}
type Player.player_action = {add : string} / {remove : string} / { clean } / {ping : string}

db /players : stringmap(Player.player)
db /players[_]/online = { false }



Player = {{

  @private state = UserContext.make(Option.none : option(Player.player))

  manage_players(player_list : stringmap(Date.date), action : Player.player_action) =
    clean(key, u, acc) =
      time = Duration.in_seconds(Duration.between(u, Date.now()))
      if time > 30. then
         do /players[key] <- { /players[key] with online = {false} }
         do Game.remove(key)
         acc
      else
         Map.add(key, u, acc)
    match action with
     | {add = u} ->       newmap = Map.add(u, Date.now(),Map.remove(u, player_list))
                          do /players[u] <- { /players[u] with online = {true} }
                          {set = newmap}     
     | {remove = a} ->    newmap = Map.remove(a, player_list)
                          do /players[a] <- { /players[a] with online = {false} }
                          do Game.remove(a)
                          {set = newmap}
 
     | {clean} ->         newmap = Map.fold(clean, player_list, Map.empty)
                          {set = newmap}
  
     | {ping = u} ->      temp = Map.remove(u, player_list)
                          {set = Map.add(u, Date.now(), temp)}


  players = Session.cloud("players", Map.empty, manage_players)

  get() = 
    UserContext.execute((a -> a), state)

  login() = 
    authenticate(username, passwd) =
      user = ?/players[username]
      match user with
       | {some = u} -> if u.pwd == Crypto.Hash.md5(passwd) then 
                        do UserContext.change(( _ -> Option.some(u)), state)
                        Dom.transform([#content <- Pow4.init(u)])
                       else
                        do Dom.transform([#afficheur <- <>Erreur de connexion !</>])
                        Dom.set_class(#afficheur, "afficheur_erreur")
       | {none} -> new = { name = username ; pwd = Crypto.Hash.md5(passwd) ; online = true ; rank = 999 } : Player.player
                   do /players[username] <- new
                   do UserContext.change(( _ -> Option.some(new)), state) 
                   Dom.transform([#content <- Pow4.init(new)]) 
    <table border=0 >
           <tr>
                <td>Name :</td><td><input id=#login_user /></td>
           </tr><tr>
                <td>Password :</td>
                <td><input id=#login_passwd type=password onnewline={ _ -> authenticate(String.to_lower(Dom.get_content(#login_user)), Dom.get_content(#login_passwd)) }/></td>
           </tr><tr>
                <td></td>
                <td><button onclick={ _ -> authenticate(String.to_lower(Dom.get_content(#login_user)), Dom.get_content(#login_passwd)) } >Se connecter / Créer le compte</button></td>
           </tr>
     </table>

  ping(name)=
    Session.send(players, {ping = name})

  @server
  clean()=
    Scheduler.timer(10000, ( -> Session.send(players, {clean}))) // Clean every ten seconds

  scoreboard() = 
    users = List.sort_by((u -> u.rank), Map.fold((_, v, acc -> List.add(v, acc)), /players, List.empty))
    table = List.fold((elt, acc -> <>{acc}</><tr><td>{elt.name}</td><td>{elt.rank}</td><td>{if elt.online == { true } then "Y" else "N"}</td></tr>), users, <></>)
    <h4> Scoreboard </h4><table><thead><td>Name</td><td>Rank</td><td> Online </td></thead>{table}</table>

}}

// logout everybody on server start
do Map.fold((k,_,_ -> do jlog(k)
                      do /players[k] <- { /players[k] with online = { false } }
                      void
             ), /players, void)
// Launch the clean
do Player.clean()
