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

type Game.game = {
  playerblue : option(string) ;
  playerred : option(string) ;
  turn : {debut} / {blue} / {red} / {fin} ;
  grid : list(list({empty}/{blue}/{red})) ;
}

type Game.action = {
  player : string ;
  push : int ;
}

type Game.message = { add : string } / 
                    { remove : string } /
                    { action : Game.action } 

@server Game = {{

  emptygrid = List.init( ( _ -> List.init( (_ -> {empty}), Pow4.conf.line)), Pow4.conf.col) 

  default = {
    playerblue = Option.none ;
    playerred = Option.none ;
    turn = {debut} ;
    grid = emptygrid ;
  }

  manage_games(game_list : list(Game.game), msg : Game.message) =
    match msg with
     | {add = u} ->     newlist = find_game_for(game_list : list(Game.game), u)
                        { set = newlist }
     | {remove = u} ->  newlist = player_quit(game_list, u)
                        { set = newlist }
     | {action = a} ->  newlist = action(game_list, a)
                        { set = newlist }

  games = Session.cloud("games", List.empty, manage_games)

  add(u) = Session.send(games, {add = u})
  remove(u) = Session.send(games, {remove = u})
  click(u, col) = 
    do jlog("{u} click on {col}")
    Session.send(games, {action = { player = u ; push = col }})

  find_game_for(game_list : list(Game.game), u) =
    fun(v, acc)=
      if v.playerred != Option.none then
        List.add(v, acc)
      else
        do Grid.broadcast({txt = "Game starting"}, u)
        do Grid.broadcast({ txt = "Game starting" }, Option.get(v.playerblue))
        List.add({ v with playerred = Option.some(u) ; turn = {blue} }, acc) // TODO : Add random for blue or red
    result = List.fold(fun , game_list, List.empty)
    find_a_place = List.fold((v, acc -> if v.playerred == Option.some(u) then {true} else acc), result, {false})
    if find_a_place == {true} then
      result
    else
      do Grid.broadcast({ txt = "Waiting a challenger" }, u) 
      List.add({ default with playerblue = Option.some(u) }, game_list)

  player_quit(game_list, u) =
    do jlog("{u} : A member quiting a game is not yet coded")
    game_list

  /*
   Cette fonction ajoute un pion dans une colone
   On a vérifié au préalabla qu'il restait au moins une place
   Elle retourne la nouvelle grille
  */
  push_in_grid(col, grid, pion) =
    color = match pion with
             | {blue} -> {blue}
             | {red} -> {red}
             | _ -> {empty}
    add_in_col(l, color)=
      List.init((i -> case = Option.get(List.get( i , l))
                      if i == 9 then
                        if case == {empty} then 
                          color
                        else
                          case 
                      else
                        nextcase = Option.get(List.get( i + 1 , l))
                        if nextcase != {empty} then 
                          if case == {empty} then
                            color
                          else
                            case
                        else
                          case), Pow4.conf.line)
    List.init((i -> if i == col then
                      add_in_col(Option.get(List.get( i , grid)), color)
                    else
                      Option.get(List.get( i , grid))), Pow4.conf.col)


  action(game_list, a) =
    play(game, action, color) =
      player = action.player
      col = action.push
      fullcol = Option.get( List.get( col, game.grid ))
      if Option.get( List.get( 0, fullcol )) != {empty} then
        do Grid.broadcast({error = "You can't push in this col !"}, player)
        game
      else
        do Grid.broadcast({play = action ; ~color }, Option.get(game.playerred))
        do Grid.broadcast({play = action ; ~color }, Option.get(game.playerblue))
        newgrid = push_in_grid(col, game.grid, color)
        nexturn = if color == {blue} then {red} else {blue}
        { game with turn = nexturn ; grid = newgrid }

    fun(v, acc)=
      if v.playerred == Option.some(a.player) then
        match v.turn with
         | {debut} -> do Grid.broadcast({error = "Please wait a challenger !"}, a.player)
                      List.add(v,acc)
         | {blue} ->  do Grid.broadcast({error = "Please wait your turn !"}, a.player)
                      List.add(v,acc)
         | {red} ->   next = play(v, a, {red})
                      List.add(next,acc)
         | {fin} ->   do Grid.broadcast({error = "The game is finished !"}, a.player)
                      List.add(v,acc)
      else 
        if v.playerblue == Option.some(a.player) then
          match v.turn with
           | {debut} -> do Grid.broadcast({error = "Please wait a challenger !"}, a.player)
                        List.add(v,acc)
           | {blue} ->  next = play(v, a, {blue})
                        List.add(next,acc)
           | {red} ->   do Grid.broadcast({error = "Please wait your turn !"}, a.player)
                        List.add(v,acc)
           | {fin} ->   do Grid.broadcast({error = "The game is finished !"}, a.player)
                        List.add(v,acc)
        else
          List.add(v,acc)
    List.fold(fun, game_list, List.empty)

}}
