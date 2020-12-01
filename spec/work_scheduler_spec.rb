require 'set'

# Scheduling work on a jobsite is one of the most difficult tasks in
# construction management. Different contractors work on different
# trades and can only do so much work in a single day. We need to
# make sure that we have the right people on the job site every day
# and anticipate how many days it will take to complete a set of tasks.
#
# *Requirements:*
#
#  ** Your solution should prefer to finish the work as fast as possible
#  ** When possible, your solution should prefer the worker with the lower value for the cost attribute

RSpec.describe WorkScheduler do
  describe 'simple schedules' do
    let(:workers) do
      [
        {
          email: 'alice@example.com',
          trades: ['brickwork', 'drywall'],
          cost: 100
        },
        {
          email: 'bob@brickwork.com',
          trades: ['brickwork'],
          cost: 90
        },
        {
          email: 'charlie@cement.com',
          trades: ['cement'],
          cost: 80
        },
        {
          email: 'wally@walls.com',
          trades: ['cement', 'drywall'],
          cost: 95
        },
      ]
    end

    let(:scheduler) { WorkScheduler::Scheduler.new(workers) }

    it 'can find a suitable worker for a task' do
      expect(scheduler.suitable_workers('cement')).to match_array(['charlie@cement.com', 'wally@walls.com'])
      expect(scheduler.suitable_workers('brickwork')).to match_array(['alice@example.com', 'bob@brickwork.com'])
      expect(scheduler.suitable_workers('drywall')).to match_array(['alice@example.com', 'wally@walls.com'])
    end

    it 'can build a simple schedule for one day' do
      expect(scheduler.schedule_one_day(['cement'])).to match_array(['charlie@cement.com'])
      expect(scheduler.schedule_one_day(['brickwork'])).to match_array(['bob@brickwork.com'])
      expect(scheduler.schedule_one_day(['drywall'])).to match_array(['wally@walls.com'])
      expect(scheduler.schedule_one_day(['cement', 'drywall'])).to match_array(['charlie@cement.com', 'wally@walls.com'])
      expect(scheduler.schedule_one_day(['cement', 'brickwork'])).to match_array(['charlie@cement.com', 'bob@brickwork.com'])
      expect(scheduler.schedule_one_day(['drywall', 'brickwork'])).to match_array(['wally@walls.com', 'bob@brickwork.com'])
      expect(scheduler.schedule_one_day(['cement', 'brickwork', 'drywall'])).to match_array(
        ['charlie@cement.com', 'bob@brickwork.com', 'wally@walls.com'])
    end

    it 'does not double book workers' do
      expect(scheduler.schedule_one_day(['cement', 'cement', 'cement'])).to match_array(['charlie@cement.com', 'wally@walls.com'])
      expect(scheduler.schedule_one_day(['brickwork', 'brickwork', 'brickwork'])).to match_array(['bob@brickwork.com', 'alice@example.com'])
      expect(scheduler.schedule_one_day(['drywall', 'drywall', 'drywall'])).to match_array(['wally@walls.com', 'alice@example.com'])
    end

     it 'can schedule multiple days of work' do
       expect(scheduler.schedule_all_tasks(['brickwork', 'brickwork', 'brickwork'])).to(
         start_with(
           a_collection_including('bob@brickwork.com', 'alice@example.com')
         ).and(
           end_with(
             a_collection_including('bob@brickwork.com'))))

       expect(scheduler.schedule_all_tasks(['drywall', 'drywall', 'drywall'])).to(
         start_with(
           a_collection_including('wally@walls.com', 'alice@example.com')
         ).and(
           end_with(
             a_collection_including('wally@walls.com')
           )))

       expect(scheduler.schedule_all_tasks(['cement', 'cement', 'cement'])).to(
         start_with(
           a_collection_including('charlie@cement.com', 'wally@walls.com')
         ).and(
           end_with(
             a_collection_including('charlie@cement.com'))))
     end

     it 'can schedule all work optimistically' do
       expect(scheduler.schedule_all_tasks(['cement', 'cement', 'cement', 'brickwork'])).to(
         start_with(
           a_collection_including('charlie@cement.com', 'bob@brickwork.com', 'wally@walls.com')
         ).and(
           end_with(
             a_collection_including('charlie@cement.com'))))
       expect(scheduler.schedule_all_tasks(['cement', 'cement', 'drywall', 'drywall', 'cement', 'brickwork'])).to(
         start_with(
           a_collection_including('bob@brickwork.com', 'charlie@cement.com', 'alice@example.com', 'wally@walls.com')
         ).and(
           end_with(
             a_collection_including('charlie@cement.com', 'wally@walls.com'))))
       expect(scheduler.schedule_all_tasks(['cement', 'cement', 'brickwork', 'brickwork', 'cement', 'brickwork'])).to(
         start_with(
           a_collection_including('charlie@cement.com', 'bob@brickwork.com', 'alice@example.com', 'wally@walls.com')
         ).and(
           end_with(
             a_collection_including('charlie@cement.com', 'bob@brickwork.com'))))
     end
  end
end
