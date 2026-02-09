SMODS.Atlas {
  key = "modicon",
  path = "FlipbookIcon.png",
  px = 34,
  py = 34
}

-- The below six functions worked in Phanta before I modified them, however I haven't tested these, so they may not work properly.
function Card:flipbook_set_anim_state(state, dont_reset_t)
  self.config.center.flipbook_anim_current_state = state
  if not dont_reset_t then
    self.config.center.flipbook_anim_t = 0
  elseif self.config.center.flipbook_anim.length then
    self.config.center.flipbook_anim_t = self.config.center.flipbook_anim_t % self.config.center.flipbook_anim.length
  end
end

function Card:flipbook_set_anim_extra_state(state, layer, dont_reset_t)
  if not self.config.center.flipbook_anim_extra_current_states then self.config.center.flipbook_anim_extra_current_states = {} end
  if not layer then layer = "extra" end
  self.config.center.flipbook_anim_extra_current_states[layer] = state

  if not self.config.center.flipbook_anim_extra_t then self.config.center.flipbook_anim_extra_t = {} end
  if not dont_reset_t then
    self.config.center.flipbook_anim_extra_t[layer] = 0
  elseif self.config.center.flipbook_anim_extra[layer] then
    self.config.center.flipbook_anim_extra_t[layer] = self.config.center.flipbook_anim_extra_t[layer] % self.config.center.flipbook_anim_extra[layer].length
  end
end

function SMODS.Center:flipbook_set_anim_state(state, dont_reset_t)
  self.flipbook_anim_current_state = state
  if not dont_reset_t then
    self.flipbook_anim_t = 0
  elseif self.flipbook_anim.length then
    self.flipbook_anim_t = self.flipbook_anim_t % self.flipbook_anim.length
  end
end

function SMODS.Center:flipbook_set_anim_extra_state(state, layer, dont_reset_t)
  if not self.flipbook_anim_extra_current_states then self.flipbook_anim_extra_current_states = {} end
  if not layer then layer = "extra" end
  self.flipbook_anim_extra_current_states[layer] = state

  if not self.flipbook_anim_extra_t then self.flipbook_anim_extra_t = {} end
  if not dont_reset_t then
    self.flipbook_anim_extra_t[layer] = 0
  elseif self.flipbook_anim_extra[layer] then
    self.flipbook_anim_extra_t[layer] = self.flipbook_anim_extra_t[layer] % self.flipbook_anim_extra[layer].length
  end
end

function flipbook_set_anim_state(center, state, dont_reset_t)
  center.flipbook_anim_current_state = state
  if not dont_reset_t then
    center.flipbook_anim_t = 0
  elseif center.flipbook_anim.length then
    center.flipbook_anim_t = center.flipbook_anim_t % center.flipbook_anim.length
  end
end

function flipbook_set_anim_extra_state(center, state, layer, dont_reset_t)
  if not center.flipbook_anim_extra_current_states then center.flipbook_anim_extra_current_states = {} end
  if not layer then layer = "extra" end
  center.flipbook_anim_extra_current_states[layer] = state

  if not center.flipbook_anim_extra_t then center.flipbook_anim_extra_t = {} end
  if not dont_reset_t then
    center.flipbook_anim_extra_t[layer] = 0
  elseif center.flipbook_anim_extra[layer] then
    center.flipbook_anim_extra_t[layer] = center.flipbook_anim_extra_t[layer] % center.flipbook_anim_extra[layer].length
  end
end

get_pos_from_flipbook_table = function(pos) -- Not really intended for use outside this script.
  return pos and (pos.pos or (pos.x and pos.y and pos)) or { x = 0, y = 0 }
end

SMODS.DrawStep {
  key = 'extra',
  order = 21,
  func = function(self, layer)
    if not self.flipbook_extra and self.config.center.flipbook_pos_extra then
      self.flipbook_extra = {}
      local fpe = self.config.center.flipbook_pos_extra
      if fpe.x and fpe.y then -- flipbook_pos_extra = { x = ?, y = ?, atlas = "ExampleAtlas" }
        local atlas = G.ASSET_ATLAS[fpe.atlas or self.config.center.atlas]
        self.flipbook_extra.extra = Sprite(0, 0, atlas.px, atlas.py, atlas, { x = fpe.x, y = fpe.y })
      else -- flipbook_pos_extra = { example = { x = ?, y = ? }, example2 = { x = ?, y = ?, atlas = "ExampleAtlas" } }
        for k, v in pairs(fpe) do
          local atlas = G.ASSET_ATLAS[v and v.atlas or self.config.center.atlas]
          self.flipbook_extra[k] = Sprite(0, 0, atlas.px, atlas.py, atlas, get_pos_from_flipbook_table(v))
        end
      end
    end
    if self.flipbook_extra then
      if self.config.center.discovered or (self.params and self.params.bypass_discovery_center) then
        local fpe = self.config.center.flipbook_pos_extra
        if fpe.x and fpe.y then
          fpe = { extra = self.config.center.flipbook_pos_extra }
        end
        for k, v in pairs(fpe) do
          self.flipbook_extra[k]:set_sprite_pos(get_pos_from_flipbook_table(v))
          self.flipbook_extra[k].role.draw_major = self
          if (self.edition and self.edition.negative and (not self.delay_edition or self.delay_edition.negative)) or (self.ability.name == 'Antimatter' and (self.config.center.discovered or self.bypass_discovery_center)) then
            self.flipbook_extra[k]:draw_shader('negative', nil, self.ARGS.send_to_shader, nil, self.children.center)
          elseif not self:should_draw_base_shader() then
          elseif not self.greyed then
            self.flipbook_extra[k]:draw_shader('dissolve', nil, nil, nil, self.children.center)
          end

          if self.ability.name == 'Invisible Joker' and (self.config.center.discovered or self.bypass_discovery_center) then
            if self:should_draw_base_shader() then
              self.flipbook_extra[k]:draw_shader('voucher', nil, self.ARGS.send_to_shader, nil, self.children.center)
            end
          end

          local center = self.config.center
          if center.draw_extra and type(center.draw_extra) == "function" then
            center:draw_extra(self, layer)
          end
          if center.draw_extra and type(center.draw_extra) == "table"
              and center.draw_extra[k] and type(center.draw_extra[k]) == "function" then
            (center.draw_extra[k])(self, layer)
          end

          local edition = self.delay_edition or self.edition
          if edition then
            for kk, vv in pairs(G.P_CENTER_POOLS.Edition) do
              if edition[vv.key:sub(3)] and vv.shader then
                if type(v.draw) == 'function' then
                  vv:draw(self, layer)
                else
                  self.flipbook_extra[k]:draw_shader(vv.shader, nil, self.ARGS.send_to_shader, nil, self.children.center)
                end
              end
            end
          end
          if (edition and edition.negative) or (self.ability.name == 'Antimatter' and (self.config.center.discovered or self.bypass_discovery_center)) then
            self.flipbook_extra[k]:draw_shader('negative_shine', nil, self.ARGS.send_to_shader, nil, self.children.center)
          end
        end
      end
    end
  end,
  conditions = { vortex = false, facing = 'front' }
}



local update_ref = Game.update
function Game:update(dt)
  for k, v in pairs(G.P_CENTERS) do
    if not v.default_pos then v.default_pos = v.pos end
    if not v.default_flipbook_pos_extra then v.default_flipbook_pos_extra = v.flipbook_pos_extra end

    handle_flipbook_anim(v, dt)
    handle_flipbook_anim_extra(v, dt)
  end

  return update_ref(self, dt)
end

function handle_flipbook_anim(v, dt)
  if v.flipbook_anim_states or v.flipbook_anim then
    v.flipbook_anim = format_flipbook_anim(v.flipbook_anim_states and v.flipbook_anim_current_state and
      v.flipbook_anim_states[v.flipbook_anim_current_state] and v.flipbook_anim_states[v.flipbook_anim_current_state].anim or
      v.flipbook_anim)
    if not v.flipbook_anim then
      v.pos = v.default_pos
    else
      local loop = v.flipbook_anim_states and v.flipbook_anim_current_state and
          v.flipbook_anim_states[v.flipbook_anim_current_state] and v.flipbook_anim_states[v.flipbook_anim_current_state].loop
      if loop == nil then loop = true end -- IMPORTANT: DO NOT SIMPLIFY TO not loop, AS FALSE IS ALLOWED.
      if not v.flipbook_anim_t then v.flipbook_anim_t = 0 end
      if not v.flipbook_anim.length then
        v.flipbook_anim.length = 0
        for _, frame in ipairs(v.flipbook_anim) do
          v.flipbook_anim.length = v.flipbook_anim.length + (frame.t or 0)
        end
      end
      v.flipbook_anim_t = v.flipbook_anim_t + dt
      if not loop and v.flipbook_anim_t >= v.flipbook_anim.length then
        local continuation = v.flipbook_anim_states[v.flipbook_anim_current_state].continuation
        if continuation then
          v.flipbook_anim_current_state = continuation
          v.flipbook_anim_t = 0
          handle_flipbook_anim(v, dt)
          return
        else
          v.flipbook_anim_t = v.flipbook_anim.length
        end
      elseif loop then
        v.flipbook_anim_t = v.flipbook_anim_t % v.flipbook_anim.length
      end
      local ix = 0
      local t_tally = 0
      for _, frame in ipairs(v.flipbook_anim) do
        ix = ix + 1
        t_tally = t_tally + frame.t
        if t_tally > v.flipbook_anim_t then break end
      end
      v.pos.x = v.flipbook_anim[ix].x
      v.pos.y = v.flipbook_anim[ix].y
    end
  end
end

function handle_flipbook_anim_extra(v, dt)
  if v.flipbook_anim_extra_states or v.flipbook_anim_extra then
    if v.flipbook_anim_extra_states then
      local first = next(v.flipbook_anim_extra_states)
      if not first then
        return                                             -- No states.
      elseif v.flipbook_anim_extra_states[first].anim then -- The animation state list doesn't give multiple layers.
        v.flipbook_anim_extra_states = { extra = v.flipbook_anim_extra_states }
      end

      -- If current states isn't defined or current states isn't a table (assumedly it's a string, it may not be), then format to a table, or use "default" if all else fails.
      if not v.flipbook_anim_extra_current_states or type(v.flipbook_anim_extra_current_states) ~= "table" then
        v.flipbook_anim_extra_current_states = { extra = v.flipbook_anim_extra_current_states or v.flipbook_anim_extra_current_state or "default" }
      end

      local temp = {}
      for k, layer in pairs(v.flipbook_anim_extra_states) do
        temp[k] = v.flipbook_anim_extra_states[k][v.flipbook_anim_extra_current_states[k]].anim
      end
      v.flipbook_anim_extra = temp
    else
      local first = next(v.flipbook_anim_extra)
      if not first then
        return                            -- There's nothing in the animation.
      elseif type(first) == "number" then -- The animation doesn't give multiple layers.
        v.flipbook_anim_extra = { extra = v.flipbook_anim_extra }
      end
    end

    for k, layer in pairs(v.flipbook_anim_extra) do
      v.flipbook_anim_extra[k] = format_flipbook_anim(layer)
    end
    if not v.flipbook_anim_extra then
      v.flipbook_pos_extra = v.default_flipbook_pos_extra
    else
      for k, layer in pairs(v.flipbook_anim_extra) do
        local loop = v.flipbook_anim_extra_states and v.flipbook_anim_extra_states[k]
            and v.flipbook_anim_extra_current_states and v.flipbook_anim_extra_current_states[k]
            and v.flipbook_anim_extra_states[k][v.flipbook_anim_extra_current_states[k]]
            and v.flipbook_anim_extra_states[k][v.flipbook_anim_extra_current_states[k]].loop
        if loop == nil then loop = true end -- IMPORTANT: DO NOT SIMPLIFY TO not loop, AS FALSE IS ALLOWED.

        if not v.flipbook_anim_extra_t then v.flipbook_anim_extra_t = {} end
        if not v.flipbook_anim_extra_t[k] then
          v.flipbook_anim_extra_t[k] = 0
        else
          v.flipbook_anim_extra_t[k] = v.flipbook_anim_extra_t[k] + dt
        end

        if not layer.length then
          layer.length = 0
          for _, frame in ipairs(layer) do
            layer.length = layer.length + (frame.t or 0)
          end
        end

        if not loop and v.flipbook_anim_extra_t[k] >= layer.length then
          local continuation = v.flipbook_anim_extra_states[k][v.flipbook_anim_extra_current_states[k]].continuation
          if continuation then
            v.flipbook_anim_extra_current_states[k] = continuation
            v.flipbook_anim_extra_t[k] = 0
            handle_flipbook_anim_extra(v, dt)
          else
            v.flipbook_anim_extra_t[k] = layer.length
          end
        elseif loop then
          v.flipbook_anim_extra_t[k] = v.flipbook_anim_extra_t[k] % layer.length
        end

        local ix = 0
        local t_tally = 0
        for _, frame in ipairs(layer) do
          ix = ix + 1
          t_tally = t_tally + frame.t
          if t_tally > v.flipbook_anim_extra_t[k] then break end
        end
        if not v.flipbook_pos_extra then v.flipbook_pos_extra = {} end
        if not v.flipbook_pos_extra[k] then v.flipbook_pos_extra[k] = {} end
        v.flipbook_pos_extra[k].x = layer[ix].x
        v.flipbook_pos_extra[k].y = layer[ix].y
      end
    end
  end
end

function format_flipbook_anim(anim)
  if not anim then return nil end
  local new_anim = {}
  for _, frame in ipairs(anim) do
    if frame and (frame.x or (frame.xrange and frame.xrange.first and frame.xrange.last)) and (frame.y or (frame.yrange and frame.yrange.first and frame.yrange.last)) then
      local firsty = frame.y or frame.yrange.first
      local lasty = frame.y or frame.yrange.last
      for y = firsty, lasty, firsty <= lasty and 1 or -1 do
        local firstx = frame.x or frame.xrange.first
        local lastx = frame.x or frame.xrange.last
        for x = firstx, lastx, firstx <= lastx and 1 or -1 do
          new_anim[#new_anim + 1] = { x = x, y = y, t = frame.t or 0 }
        end
      end
    end
  end
  new_anim.t = anim.t
  return new_anim
end

--[[

SMODS.Joker:take_ownership("j_joker", {
  pos = { x = 8, y = 1 },
  flipbook_pos_extra = { first = { x = 0, y = 3, atlas = "phanta_Phanta" }, second = { x = 1, y = 3, atlas = "phanta_Phanta" } },
  flipbook_anim_extra = { first = { { x = 0, y = 3, t = 1 }, { x = 2, y = 3, t = 0.5 } }, second = { { xrange = { first = 1, last = 5 }, y = 3, t = 0.1 } } }
}, true)

SMODS.Joker:take_ownership("j_chaos", {
  flipbook_anim_extra = {
    { x = 1, y = 9, t = 0.5 },
    { x = 2, y = 9, t = 0.5 },
  }
}, true)

SMODS.Joker:take_ownership("j_lusty_joker", {
  flipbook_anim_extra = {
    extra1 = { { x = 1, y = 9, t = 0.5 }, { x = 2, y = 9, t = 0.5 } },
    extra2 = { { x = 3, y = 9, t = 0.1 }, { x = 4, y = 9, t = 0.1 } },
  }
}, true)

SMODS.Joker:take_ownership("j_greedy_joker", {
  flipbook_anim_extra_states = {
    blah = {
      extra1 = { anim = { { x = 1, y = 9, t = 8 }, { x = 2, y = 9, t = 2 } }, loop = false, continuation = "extra2" },
      extra2 = { anim = { { x = 3, y = 9, t = 0.1 }, { x = 4, y = 9, t = 0.1 } }, loop = true },
    },
    foo = {
      gwah = { anim = { { xrange = { first = 8, last = 9 }, y = 9, t = 0.111111111 } } }
    }
  },
  flipbook_anim_extra_current_states = { blah = "extra1", foo = "gwah" }
}, true)
]] --
