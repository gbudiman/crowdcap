class Potential < ApplicationRecord
  def self.fetch_random
    return {
      response: 'success'
    }
  end

  def self.submit_eval(id:, val:)
    return {
      response: 'success'
    }
  end
end
