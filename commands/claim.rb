if ctx.db.admin_count == 0
  ctx.db.make_user_admin(ctx.user.hostmask)
  puts "Congratulations, you (#{ctx.user.hostmask}) were able to claim this Mewtwo instance and become an admin!"
else
  puts "This Mewtwo instance is already claimed!"
end
