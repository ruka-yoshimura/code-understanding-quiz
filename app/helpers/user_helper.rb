module UserHelper
  def user_title(user)
    level = user.level
    case level
    when 1..9
      "ビギナー"
    when 10..19
      "見習いエンジニア"
    when 20..29
      "コードの探究者"
    when 30..39
      "コードスペシャリスト"
    when 40..49
      "コードマスター"
    else # 50以上
      "レジェンド"
    end
  end

  def user_title_color(user)
    level = user.level
    case level
    when 1..9
      "text-gray-500"
    when 10..19
      "text-green-500"
    when 20..29
      "text-blue-500"
    when 30..39
      "text-purple-500"
    when 40..49
      "text-red-500"
    else
      "text-yellow-500"
    end
  end
end
