require 'leankit'

class KanBan

    # Internal tracking params - private
    attr_accessor :lanes
    attr_accessor :cards
    attr_accessor :users


    def initialize()
        @lanes = Hash.new
        @cards = Hash.new
        @users = Hash.new

        LeanKit::Config.email = ENV['leankit_email']
        LeanKit::Config.password = ENV['leankit_pass']
        LeanKit::Config.account = ENV['leankit_account']

        begin
            identifiers = LeanKit::Board.get_identifiers('104677814')
            stream = LeanKit::Board.find('104677814')[0]['Lanes']
        rescue
            return
        end

        parse_users(identifiers[0]["BoardUsers"])
        parse_lanes(stream)
    end

    def parse_users(lkusers)
        # append user name to hash, assign zero cards
        lkusers.each do |luser|
            @users[luser["Id"]] = { label: luser["Name"].split("@")[0].sub('.', ' '), value: 0}
        end
    end

    def increment_user_cards(userid)
        @users[userid][:value] += 1
    end

    def users_with_cards()
        @users.each_key do |k|
            if @users[k][:value] == 0
                @users.delete(k)
            end
        end
        @users
    end

    def parse_lanes(stream)
        stream.each do |lane|
            for card in lane['Cards'] do
                if card["AssignedUserIds"].length > 0
                    card["AssignedUserIds"].each do |userid|
                        increment_user_cards(userid)
                    end 
                end
            end
        end
    end

end


SCHEDULER.every '5m', :first_in => 0 do
  r = KanBan.new()
  send_event('usercards', { items: r.users_with_cards().values })
end