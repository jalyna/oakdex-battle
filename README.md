# <img src="https://v20.imgup.net/oakdex_logfbad.png" alt="fixer" width=282>

[![Build Status](https://travis-ci.org/jalyna/oakdex-battle.svg?branch=master)](https://travis-ci.org/jalyna/oakdex-battle) [![Maintainability](https://api.codeclimate.com/v1/badges/ef91681257a6900f03ac/maintainability)](https://codeclimate.com/github/jalyna/oakdex-battle/maintainability) [![Test Coverage](https://api.codeclimate.com/v1/badges/ef91681257a6900f03ac/test_coverage)](https://codeclimate.com/github/jalyna/oakdex-battle/test_coverage)

Based on [oakdex-pokedex](https://github.com/jalyna/oakdex-pokedex).

## Getting Started

```ruby
require 'oakdex/battle'

pok1 = Oakdex::Battle::Pokemon.create('Eevee', level: 10)
pok2 = Oakdex::Battle::Pokemon.create('Bulbasaur', {
  exp: 120,
  gender: 'female',
  ability: 'Soundproof',
  nature: 'Bashful',
  item: 'Earth Plate',
  hp: 2,
  iv: {
    hp: 8,
    atk: 12,
    def: 31,
    sp_atk: 12,
    sp_def: 5,
    speed: 14
  },
  ev: {
    hp: 8,
    atk: 12,
    def: 99,
    sp_atk: 4,
    sp_def: 12,
    speed: 14
  },
  moves: [
    ['Swords Dance', 12, 30],
    ['Cut', 40, 44]
  ]
})
pok3 = Oakdex::Battle::Pokemon.create('Altaria', level: 20)
pok4 = Oakdex::Battle::Pokemon.create('Elekid', level: 14)

trainer1 = Oakdex::Battle::Trainer.new('Ash', [pok1])
trainer2 = Oakdex::Battle::Trainer.new('Misty', [pok2])
trainer3 = Oakdex::Battle::Trainer.new('Jessie', [pok3])
trainer4 = Oakdex::Battle::Trainer.new('James', [pok4])

battle = Oakdex::Battle.new([trainer1], [trainer2]) # 1v1
battle = Oakdex::Battle.new([trainer1], [trainer2], type: :double)
battle = Oakdex::Battle.new([trainer1], [trainer2], type: :triple)
battle = Oakdex::Battle.new([trainer1], [trainer2], type: :horde)

battle = Oakdex::Battle.new([trainer1, trainer3], [trainer2, trainer4], type: :double)

battle.choose_action
battle.choose_action
battle.next_turn

battle.choose_action
battle.choose_action
battle.next_turn

battle.ended?
battle.log
battle.winner # => trainer2
```


## Contributing

I would be happy if you want to add your contribution to the project. In order to contribute, you just have to fork this repository.

## License

MIT License. See the included MIT-LICENSE file.

## Credits

Logo Icon by [Roundicons Freebies](http://www.flaticon.com/authors/roundicons-freebies).
