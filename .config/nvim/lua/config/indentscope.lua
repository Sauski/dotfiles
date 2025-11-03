return {
  symbol = '│',
  options = { try_as_border = true },
  draw = {
    delay = 0,
    animation = require('mini.indentscope').gen_animation.cubic({ easing = 'in-out', duration = 30, unit = 'total' }),
  },
}
