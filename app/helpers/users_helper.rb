# frozen_string_literal: true

module UsersHelper
  def user_title(user)
    user_title_text(user.level)
  end

  def user_title_text(level)
    case level
    when 1..9
      'ビギナー'
    when 10..19
      '見習いエンジニア'
    when 20..29
      'コードの探究者'
    when 30..39
      'コードスペシャリスト'
    when 40..49
      'コードマスター'
    else # 50以上
      'レジェンド'
    end
  end

  def user_title_color(user)
    level = user.level
    case level
    when 1..9
      'text-gray-500'
    when 10..19
      'text-green-500'
    when 20..29
      'text-blue-500'
    when 30..39
      'text-purple-500'
    when 40..49
      'text-red-500'
    else
      'text-yellow-500'
    end
  end

  def user_rank_class(user)
    base_class = 'inline-block font-extrabold uppercase tracking-widest px-4 py-1.5 rounded-full text-[10px] border'

    color_class = case user.level
                  when 1..9
                    'bg-slate-500/20 text-slate-400 border-slate-500/40'
                  when 10..19
                    'bg-emerald-500/20 text-emerald-400 border-emerald-500/40'
                  when 20..29
                    'bg-blue-500/20 text-blue-400 border-blue-500/40'
                  when 30..39
                    'bg-purple-500/20 text-purple-400 border-purple-500/40'
                  when 40..49
                    'bg-rose-500/20 text-rose-400 border-rose-500/40'
                  else
                    'bg-amber-500/20 text-amber-400 border-amber-500/40'
                  end

    "#{base_class} #{color_class}"
  end
end
