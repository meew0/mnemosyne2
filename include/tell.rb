IRC_BOLD = 2.chr

def fancy_format(parsed)
  has_multis = parsed.any? { |e| e.size > 1 }

  reduced = parsed.map do |e|
    e[-1] = "or " + e[-1] if e.size > 1
    e.join(e.size > 2 ? ", " : " ")
  end

  reduced[-1] = IRC_BOLD + (has_multis ? "as well as " : "and ") + IRC_BOLD + reduced[-1] if reduced.size > 1
  reduced.join(reduced.size > 2 ? (has_multis ? "; " : ", ") : " ")
end

def parse_targets(targets)
  targets.split(',').map { |e| e.split(':') }
end

def unparse_targets(targets)
  targets.map { |e| e.join(':') }.join(',')
end

def count_target_hits(parsed_targets, user)
  nick = user.nick
  prefixed_username = '!' + user.hostmask.split('@').first
  new_targets = []
  count = 0
  parsed_targets.each do |e|
    sub_count = e.count { |e2| e2 == nick || e2 == prefixed_username }
    if sub_count > 0
      count += sub_count
    else
      new_targets << e
    end
  end

  [count, new_targets]
end

def collect_entries(ctx)
  tells = ctx.pctx.list('tell')
  entries = []
  tells.each do |id, content|
    targets, time_str, source_nick, source_channel, message = content.parse_csv

    count, new_targets = count_target_hits(parse_targets(targets), ctx.user)
    if count > 0
      ctx.pctx.delete('tell', id)
      unless new_targets.empty?
        # Readd the tell message so the other users can receive it in time
        new_content = [unparse_targets(new_targets), time_str, source_nick, source_channel, message].to_csv
        ctx.pctx.put('tell', id, new_content)
      end

      count.times { entries << [Time.at(time_str.to_i / 1000.0), source_nick, source_channel, message] }
    end
  end
  entries
end
