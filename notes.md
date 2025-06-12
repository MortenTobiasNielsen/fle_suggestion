### Expected interaction flow

#### Initialization
1. The integration pulls down the docker image, if not already available.
2. The integration spins up the docker image based on a user defined config.
3. The POST /config/ endpoint is called with a config (technologies enabled, teams, characters per team, inventory per character, etc.).
3. The POST /reset/ endpoint is called to reset the game with the specified config.
4. The GET /data/static/ endpoint is called with a position and radius.
5. The GET /data/meta/ endpoint is called with a position and radius.
6. The GET /data/state/ endpoint is called with a position and radius.

#### Loop
1. The POST /actions/ endpoint is called with a characterId and a list of actions to append to the action list for that character.
2. The PUT /actions/ endpoint is called with a characterId and a list of changes to the action list for that character.
3. The POST /execute/ endpoint is called once all action additions and changes has been made. The game will then go through the action list of all characters until one of the characters has no more actions. 
4. The GET /data/state/ endpoint is called with a position and radius.
5. The GET /data/meta/ endpoint might be called with a position and radius.
6. The POST /reset/ endpoint might be called to reset the game back to the initial config. This will clear actions from all characters.