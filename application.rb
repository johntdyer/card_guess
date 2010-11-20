## 
# Card guessing Tropo application
# John T. Dyer
# Voxeo Labs
# 2010 tropo.com
##


##
#
# Method determines if we have a single value, or complete card, for example we may identify a rank of Ace but still need to identify
# the suit of said card.  This helper method is what we use. 
#
##
@@validated_results=Hash.new

def check_interpretation(v)
 # @validated_results=Hash.new
  if v.nil?
    log "ERROR: NILL VALUE PASSED TO check_interpretation method, bad juju"
    
  elsif v.tag.get('rank')!=nil && v.tag.get('suit')!=nil

    @validated_results.merge!({:suit=>validate_interpretation(v,'suit')})
    @validated_results.merge!({:rank=>validate_interpretation(v,'rank')})

    log "@ NOTICE GOT: RANK => #{@validated_results[:rank]} || Confidence Score=> #{v.confidence}"
    log "@ NOTICE GOT: SUIT => #{@validated_results[:suit]} || Confidence Score=> #{v.confidence}"

   elsif v.tag.get('suit')!=nil

    @validated_results.merge!({:suit=>validate_interpretation(v,'suit')})
    @validated_results.merge!({:rank=>validate_interpretation(ask_for_rank,'suit')})

    log "@ NOTICE: GOT RANK => #{@validated_results[:rank]} || Confidence Score=> #{v.confidence}"
    log "@ NOTICE: GOT SUIT => #{@validated_results[:suit]} || Confidence Score=> #{v.confidence}"

   elsif v.tag.get('rank')!=nil
    @validated_results.merge!({:rank=>validate_interpretation(v,'rank')})
    @validated_results.merge!({:suit=>validate_interpretation(ask_for_suit,'suit')})

    log "@ NOTICE GOT: RANK => #{@validated_results[:rank]} || Confidence Score=> #{v.confidence}"
    log "@ NOTICE GOT: SUIT => #{@validated_results[:suit]} || Confidence Score=> #{v.confidence}"

   else
     log "@@@ ERROR check_interpretation method returned this =>  [:Tag('suit')=>#{v.tag.get('suit')},:Tag('rank')=>#{v.tag.get('rank')},:Confidence=> #{v.confidence}]"
  end  
   return @validated_results
end

##
#
# just what is says, validates an interpretation
#
##
 def validate_interpretation(value,item)
   @result_var = ""
   @item = item 
   ask "#{random_speech_prefix} #{value.tag.get(item)} #{random_speech_sufix}", 
     {
      :choices=>"true(Thats correct ), false( try again )",  
      :repeat      => 3,
      :onTimeout   => lambda { say 'I am sorry.  I did not hear anything.' }, 
      :onChoice    => lambda { |event| 
                                 case event.value
                                   when 'true'
                                     say "Great"
                                     log "@" * 10 + " validated #{@item} => #{value.interpretation} || #{value.confidence}"

                                     @result_var<<value.tag.get(item)
                                   when 'false'
                                     log "@" * 10 + " #{@item} ERROR in validate_interpretation method => #{value.interpretation}"
                                     case item
                                       when 'suit'
                                         validate_interpretation(ask_for_suit,'suit')
                                       when 'rank'
                                         validate_interpretation(ask_for_rank,'rank')
                                     end
                                   end
                             }
               }
               log "@" * 5 + " result_var => #{@result_var}"
               return @result_var
 end

##
#    Methods to get suit and/or spade when initial interpretation only contained one, 
#    for example call ask_for_suit when we have identified an Ace, or ask_for_rank when 
#    we have identified a spade
##

 def ask_for_suit
   @suit_val=""
   result = ask "Ok then, what was the suit?", 
                                   {
                                   :bargein=>false,
                                   :choiceConfidence=>"0.35",
                                   :choices => @base_url + "suit_grammar.xml",
                                   :timeout => 5,
                                   :repeat  => 20
                                   }

     if result.name=='choice'
       log "@@@ LOG: ask_for_suit return => #{result.choice.tag.get('suit')}"
       return result.choice
     else
       log "@@@ ERROR: Failed in ask_for_suit method"
     end
 end

 def ask_for_rank
   @rank_val=""
     result = ask "Ok then, what was the cards rank?", 
                                     {
                                     :bargein=>false,
                                     :choiceConfidence=>"0.35",
                                     :choices => @base_url + "rank_grammar.xml",
                                     :timeout => 5,
                                     :repeat  => 20
                                     }
       if result.name=='choice'
         log "@@@ LOG: ask_for_rank return => #{result.choice.tag.get('rank')}"
         return result.choice
       else
         log "@@@ ERROR: Failed in ask_for_rank method"
       end

 end

##
#
# Add some randomness for the TTS in the validate_interpretation method call
#
##
   def random_speech_prefix
     array = []
     array[0]= " pretty sure you said "
     array[1]= "I think you said"
     array[2]= "Sounds like you said "
      return array[rand(array.size)]
   end

   def random_speech_sufix
     array = []
     array[0]= " is that right?"
     array[1]= " is that correct?"
      return array[rand(array.size)]
   end

   def send_final_sms(message_to_send)
     message(message_to_send, { 
     :to => 'tel:+12312312312312123', 
     :channel=>'TEXT',
     :network=>'SMS'
     })
   end

####################################################################
#
#          START APPLICATION CODE
#
####################################################################

@base_url = "http://hosting.tropo.com/46653/www/john_card_guess/"

options={
 :choices => @base_url + "combined_grammar_example.xml",
 :timeout => 5,
 :repeat  => 20
 }

 answer

 sleep(1)
 
 result = ask "Please give me a card, any card", 
                       options.merge!({
                                 :bargein=>false,
                                 :choiceConfidence=>"0.35"
                                 })

 if result.name=='choice'
 final_hash = check_interpretation(result.choice)
   if final_hash.has_key?(:suit) && final_hash.has_key?(:rank)
       final_result = "So I have recognized a #{final_hash[:rank]} ... of ... #{final_hash[:suit]} ... as your card, game over, I win"
        send_final_sms(final_result)
        say final_result
   else
     log "@@ ERROR in main, we got something back we did not account for"
   end
 else
   log "@@@@ ERROR"
 end

 hangup