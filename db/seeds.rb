# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

User.create(login: 'dispatcher', password: 'dispatcher', user_role: 'dispatcher')
User.create(login: 'ivanov', password: 'ivanov', user_role: 'driver')
User.create(login: 'petrov', password: 'petrov', user_role: 'driver')

Truck.create(name: 'Kamaz', driver_id: User.find_by_login('ivanov').id, max_capacity: 1400)
Truck.create(name: 'Gazel', driver_id: User.find_by_login('petrov').id, max_capacity: 1400)