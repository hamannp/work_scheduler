require 'work_scheduler/version'
require 'set'
require 'ostruct'
require 'pry'

module WorkScheduler

  class Scheduler
    attr_accessor :workers, :booked

    def initialize(workers)
      @workers = workers.map { |worker| OpenStruct.new(worker) }
      @booked  = Set.new
    end

    def suitable_workers(trade)
      workers_with(trade).map(&:email)
    end

    def schedule_one_day(trades)
      schedule = trades.map do |trade|
        candidates = candidate_workers_for(trade)
        proposed   = compare(candidates)

        self.booked << proposed
        proposed
      end.compact.map(&:email)

      self.booked.clear
      schedule
    end

    def schedule_all_tasks(trades, number_of_days=5)
      number_of_days.times.map do
        schedule_one_day(trades)
      end
    end

    private

    def workers_with(trade)
      workers.select { |worker| worker.trades.include?(trade) }
    end

    def candidate_workers_for(trade)
      workers.select do |worker|
        workers_with(trade).include?(worker)
      end - self.booked.to_a
    end

    def compare(candidates)
      candidates.min { |a, b| a.cost <=> b.cost }
    end
  end

end
