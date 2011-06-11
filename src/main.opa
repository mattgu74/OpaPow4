/*
 * OpaPow4
 *
 * @author Matthieu Guffroy
 *
 */

import mattgu74.pow4

Load() = 
  player = Player.get()
  match player with
   | {some = p} -> Dom.transform([#content <- Pow4.init(p)])
   | {none} -> Dom.transform([#content <- Player.login()])

start()=
  <div id=#head />
  <div id=#afficheur class="afficheur_neutre">En attente de connexion !</div>
  <div id=#plateau ><div id=#content onready={_ -> Load()}/></div>
  <div id="white">
	<div id="explications">
		<h1>Règles</h1>
		<p>Pour ceux qui n'auraient jamais touché un puissance 4, les règles sont simples. Deux joueurs s'affrontent, à tour de rôle, pour aligner 4 pions de leur couleur le plus tôt possible dans la partie.</p><p>
		</p><p>Chaque joueur fait tomber un pion dans le plateau de jeu par tour, le premier à avoir aligné 4 pions gagne la partie et gagne 4 points. En cas de match nul, c'est à dire si le plateau est rempli sans qu'il y ai de combinaisons gagnantes, un point est donné à chaque joueur. C'était pas si compliqué, vous voyez ?</p>
	

		<h1>Conception</h1>
		<p>Ce programme a été conçu par Matthieu Guffroy en utilisant le language OPA.</p>
                <p>Design de Thomas Buffet.</p>
	</div>
  </div>


server = Server.one_page_bundle("M@ttgu74 - Pow4 Game",
       [@static_resource_directory("resources")],
       ["resources/resources.css"], start)

