//++++++++++++++++++++++
// IMPORT FILES QUERIES+
//++++++++++++++++++++++

//--------------------------------------------------------------------------------
//GAMES
//-------------------------------------------------------------------------------+

CREATE CONSTRAINT ON (game:Game) ASSERT game.GameNumber IS UNIQUE

LOAD CSV WITH HEADERS FROM "file:///game_info.csv" AS line
MERGE (game : Game {GameNumber : line.GameNumber})
ON CREATE SET game.GameNumber = line.GameNumber, game.Date = line.Date, game.HalfMoves = line.HalfMoves, game.Moves = line.Moves, game.WhiteElo = line.WhiteElo, game.BlackElo = line.BlackElo, game.Result = line.Result 

//--------------------------------------------------------------------------------
//PLAYERS
//-------------------------------------------------------------------------------+

CREATE CONSTRAINT ON (player:Player) ASSERT player.Name IS UNIQUE

LOAD CSV WITH HEADERS FROM "file:///game_info.csv" AS line
MERGE (player : Player {Name : line.White})
ON CREATE SET player.Name = line.White

LOAD CSV WITH HEADERS FROM "file:///game_info.csv" AS line
MERGE (player : Player {Name : line.Black})
ON CREATE SET player.Name = line.Black

//------------------
//Players & Games
//------------------

LOAD CSV WITH HEADERS FROM "file:///game_info.csv" AS line
MATCH (player {Name : line.White}), (game {GameNumber : line.GameNumber})
MERGE (player) - [r : Plays {Color : 'White'}] -> (game)
RETURN player.Name, type(r), game.GameNumber

LOAD CSV WITH HEADERS FROM "file:///game_info.csv" AS line
MATCH (player {Name : line.Black}), (game {GameNumber : line.GameNumber})
MERGE (player) - [r : Plays {Color : 'Black'}] -> (game)
RETURN player.Name, type(r), game.GameNumber

//--------------------------------------------------------------------------------
//TOURNAMENT
//-------------------------------------------------------------------------------+

CREATE CONSTRAINT ON (tournament:Tournament) ASSERT tournament.EventName IS UNIQUE

LOAD CSV WITH HEADERS FROM "file:///game_info.csv" AS line
MERGE (tournament : Tournament {EventName : line.Event})
ON CREATE SET tournament.EventName = line.Event, tournament.Site = line.Site, tournament.EventDate = line.EventDate

//------------------
//Tournaments & Games
//------------------

LOAD CSV WITH HEADERS FROM "file:///game_info.csv" AS line
MATCH (tournament {EventName : line.Event}), (game {GameNumber : line.GameNumber})
MERGE (tournament) - [r : Include  {round : line.Round}] -> (game)
RETURN tournament.EventName, type(r), game.GameNumber

//--------------------------------------------------------------------------------
//OPENING
//-------------------------------------------------------------------------------+

CREATE CONSTRAINT ON (openMove:OpenMove) ASSERT openMove.ECO IS UNIQUE

LOAD CSV WITH HEADERS FROM "file:///game_info.csv" AS line
MERGE (openMove : OpenMove {ECO : line.ECO})
ON CREATE SET openMove.ECO = line.ECO, openMove.Opening = line.Opening

//------------------
//Openings & Games
//------------------

LOAD CSV WITH HEADERS FROM "file:///game_info.csv" AS line
MATCH (openMove {ECO : line.ECO}), (game {GameNumber : line.GameNumber})
MERGE (openMove) - [r : Opening] -> (game)
RETURN openMove.Opening, type(r), game.GameNumber

//--------------------------------------------------------------------------------
//POSITIONS
//-------------------------------------------------------------------------------+

CREATE CONSTRAINT ON (position:Position) ASSERT position.FEN IS UNIQUE

LOAD CSV WITH HEADERS FROM "file:///game_moves.csv" AS line
MERGE (position : Position {FEN : line.FEN})
ON CREATE SET position.FEN = line.FEN

//------------------
//Positions & Games
//------------------

LOAD CSV WITH HEADERS FROM "file:///game_moves.csv" AS line
MATCH (game {GameNumber : line.GameNumber}), (position {FEN : line.FEN})
MERGE (game) - [r : Move  {Number : line.MoveNumber, GameNumber : line.GameNumber, MoveName : line.Move}] -> (position)
RETURN game.GameNumber, type(r), position.FEN

//+++++++++
// QUERIES+
//+++++++++

// Query 1
MATCH (game : Game) - [r : Move] -> (position {FEN : 'r1bqkbnrpppp1ppp2n51B2p34P35N2PPPP1PPPRNBQK2R'})
WITH COUNT(*) AS number_of_games
MATCH (game : Game) - [r : Move] -> (position {FEN : 'r1bqkbnrpppp1ppp2n51B2p34P35N2PPPP1PPPRNBQK2R'})
WHERE game.Result = 'White'
WITH COUNT(*) AS white_wins, number_of_games
RETURN 100.0*white_wins/number_of_games AS white_wins_pc

// Query 2
MATCH (game : Game) - [r : Move] -> (position {FEN : 'r1bqkbnrpppp1ppp2n51B2p34P35N2PPPP1PPPRNBQK2R'})
RETURN game.Result AS winning_color, COUNT(game.GameNumber) AS number_of_games

// Query 3
MATCH (tournament) - [r : Include] -> (game : Game) 
WITH COUNT(game.GameNumber) AS number_of_games, COLLECT(game.GameNumber) AS games, tournament.EventName AS tournament
MATCH (player : Player) - [r : Plays] -> (game : Game)
WHERE player.Name ='Karpov  Anatoly' AND game.GameNumber IN games
RETURN tournament, number_of_games, COUNT(player.Name) AS KA_games ORDER BY number_of_games DESC LIMIT 1


//Query 4
MATCH   (openMove : OpenMove {Opening : 'Ruy Lopez'}) - [r : Opening] -> (game : Game)
WITH COLLECT(game.GameNumber) AS games
MATCH (player : Player) - [r : Plays] -> (game : Game)
WHERE game.GameNumber IN games
RETURN player.Name AS player, COUNT(*) AS number_of_games
ORDER BY number_of_games DESC LIMIT 1
                          
// Query 5
MATCH (game : Game)
MATCH (player : Player)    
MATCH (p1 : Position), (p2 : Position), (p3 : Position)
MATCH (player) - [r1 : Plays] -> (game)
MATCH (game) - [r2 : Move {MoveName: 'Nc6'}] -> (p1)
MATCH (game) - [r3 : Move {MoveName: 'Bb5'}] -> (p2)
MATCH (game) - [r4 : Move {MoveName: 'a6'}] -> (p3)
WHERE TOINTEGER(r3.Number) = TOINTEGER(r2.Number)+1 AND TOINTEGER(r4.Number) = TOINTEGER(r3.Number)+1
RETURN DISTINCT player.Name AS player, COUNT(*) AS number_of_games

// Query 6
MATCH (game) - [r : Move] -> (position : Position)
MATCH (player : Player) - [: Plays] -> (game)
MATCH (tournament : Tournament) - [: Include] -> (game)
WHERE game.GameNumber = '636'
RETURN game.Date AS date, game.HalfMoves AS halfmoves, game.Moves AS moves, game.WhiteElo AS white_elo, game.BlackElo AS black_elo, game.Result AS result, tournament.EventName AS event, tournament.Site AS site, tournament.EventDate AS event_date, COLLECT(DISTINCT player.Name) AS players, COLLECT(DISTINCT r.MoveName) AS set_of_moves

// Query 7
MATCH (game : Game) - [r1 : Move] -> (p1 : Position {FEN : 'r1bqkbnrpppp1ppp2n51B2p34P35N2PPPP1PPPRNBQK2R'})
MATCH (game) - [r2 : Move {Number : TOSTRING(TOINTEGER(r1.Number) + 1)}] -> (p2 : Position)
WHERE r2.MoveName <> 'a6'
RETURN TOINT(game.GameNumber) AS game_number, game.Result AS result, r2.MoveName AS alternative_moves ORDER BY game_number