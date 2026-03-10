SMODS.Atlas {
  key = "modicon",
  path = "FlipbookIcon.png",
  px = 34,
  py = 34
}



function Sprite:flipbook_set_atlas(atlas)
  if not atlas then return end
  local new_atlas = G.ASSET_ATLAS[atlas]
  if not new_atlas then return end

  self.atlas = new_atlas

  self.sprite = love.graphics.newQuad(
    self.sprite_pos.x * self.atlas.px,
    self.sprite_pos.y * self.atlas.py,
    self.scale.x,
    self.scale.y, self.atlas.image:getDimensions())

  self.image_dims = {}
  self.image_dims[1], self.image_dims[2] = self.atlas.image:getDimensions()
end

SMODS.DrawStep {
  key = 'extra',
  order = 21,
  func = function(self, layer)
    if not self.flipbook_pos_extra and self.config and self.config.center and self.config.center.flipbook_pos_extra then
      local function copy(t)
        if type(t) ~= "table" then return t end
        local n = {}
        for k, v in pairs(t) do
          n[k] = copy(v)
        end
        return n
      end

      local ccfpe = self.config.center.flipbook_pos_extra
      if ccfpe.x and ccfpe.y then
        self.flipbook_pos_extra = { extra = copy(ccfpe) }
      else
        self.flipbook_pos_extra = copy(ccfpe)
      end
    end
    if not self.flipbook_extra and self.flipbook_pos_extra then
      self.flipbook_extra = {}
      local fpe = self.flipbook_pos_extra
      if fpe.x and fpe.y then                                                    -- flipbook_pos_extra = { x = ?, y = ?, atlas = "ExampleAtlas" }
        local atlas = G.ASSET_ATLAS[fpe.atlas or self.config.center.atlas]       -- Uses the atlas the extra pos tells it to, or the default.
        self.flipbook_extra.extra = Sprite(0, 0, atlas.px, atlas.py, atlas, { x = fpe.x, y = fpe.y })
      else                                                                       -- flipbook_pos_extra = { example = { x = ?, y = ? }, example2 = { x = ?, y = ?, atlas = "ExampleAtlas" } }
        for k, v in pairs(fpe) do
          local atlas = G.ASSET_ATLAS[v and v.atlas or self.config.center.atlas] -- Uses the atlas the layer tells it to, or the default.
          self.flipbook_extra[k] = Sprite(0, 0, atlas.px, atlas.py, atlas, { x = v.x or 0, y = v.y or 0 })
        end
      end
    end

    if self.flipbook_extra then
      if self.config.center.discovered or (self.params and self.params.bypass_discovery_center) then
        local fpe = self.flipbook_pos_extra
        if fpe.x and fpe.y then
          fpe = { extra = self.flipbook_pos_extra }
        end

        for k, v in pairs(fpe) do
          self.flipbook_extra[k]:set_sprite_pos(v)
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

          -- TO DO: Allow individual cards to choose which shaders they use, instead of their centers speaking for them.
          local center = self.config.center
          if center.flipbook_draw_extra and type(center.flipbook_draw_extra) == "function" then
            center:flipbook_draw_extra(self, layer)
          end
          if center.flipbook_draw_extra and type(center.flipbook_draw_extra) == "table"
              and center.flipbook_draw_extra[k] and type(center.flipbook_draw_extra[k]) == "function" then
            (center.flipbook_draw_extra[k])(self, layer)
          end

          local edition = self.delay_edition or self.edition
          if edition then
            for kk, vv in pairs(G.P_CENTER_POOLS.Edition) do
              if edition[vv.key:sub(3)] and vv.shader then
                if type(vv.draw) == 'function' then
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
  for k, v in pairs(G.MOVEABLES or {}) do
    local ccc = v and v.config and v.config.center
    if ccc and (ccc.flipbook_anim or ccc.flipbook_anim_extra or ccc.flipbook_anim_states or ccc.flipbook_anim_extra_states) then
      handle_flipbook_anim(v, dt)
      handle_flipbook_anim_extra(v, dt)
    end
  end

  return update_ref(self, dt)
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
          new_anim[#new_anim + 1] = { x = x, y = y, t = frame.t or 0, atlas = frame.atlas }
        end
      end
    end
  end
  new_anim.t = anim.t
  return new_anim
end

function handle_flipbook_anim(v, dt)
  if v.config.center.flipbook_anim_states or v.config.center.flipbook_anim then
    if not v.flipbook_anim_current_state then v.flipbook_anim_current_state = v.config.center.flipbook_anim_initial_state end
    if not v.flipbook_anim or v.flipbook_anim_state_cached ~= v.flipbook_anim_current_state then
      local anim = v.config.center.flipbook_anim_states
          and v.flipbook_anim_current_state
          and v.config.center.flipbook_anim_states[v.flipbook_anim_current_state]
          and v.config.center.flipbook_anim_states[v.flipbook_anim_current_state].anim

          or v.flipbook_anim
          or v.config.center.flipbook_anim

      v.flipbook_anim = format_flipbook_anim(anim)
      v.flipbook_anim_state_cached = v.flipbook_anim_current_state
    end

    if v.flipbook_anim then
      local loop = v.config.center.flipbook_anim_states and v.flipbook_anim_current_state and
          v.config.center.flipbook_anim_states[v.flipbook_anim_current_state] and v.config.center.flipbook_anim_states[v.flipbook_anim_current_state].loop
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
        local continuation = v.config.center.flipbook_anim_states[v.flipbook_anim_current_state].continuation
        if continuation then
          v.flipbook_anim_current_state = continuation
          v.flipbook_anim_t = 0
          handle_flipbook_anim(v, 0)
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
      v.children.center:set_sprite_pos({ x = v.flipbook_anim[ix].x, y = v.flipbook_anim[ix].y })
      if v.flipbook_anim[ix].atlas then v.children.center:flipbook_set_atlas(v.flipbook_anim[ix].atlas) end
    end
  end
end

function handle_flipbook_anim_extra(v, dt)
  if v.config.center.flipbook_anim_extra_states or v.config.center.flipbook_anim_extra then
    v.flipbook_anim_extra_cache = v.flipbook_anim_extra_cache or {}

    if v.config.center.flipbook_anim_extra_states then
      if not next(v.config.center.flipbook_anim_extra_states) then
        return -- No states.
      end

      -- If current states isn't defined or current states isn't a table (assumedly it's a string, it may not be), then format to a table, or use "default" if all else fails.
      if not v.flipbook_anim_extra_current_states or type(v.flipbook_anim_extra_current_states) ~= "table" then
        if v.flipbook_anim_extra_current_states then
          v.flipbook_anim_extra_current_states = { extra = v.flipbook_anim_extra_current_states }
        elseif v.config.center.flipbook_anim_extra_initial_states then
          v.flipbook_anim_extra_current_states = v.config.center.flipbook_anim_extra_initial_states
        elseif v.config.center.flipbook_anim_extra_initial_state then
          v.flipbook_anim_extra_current_states = { extra = v.config.center.flipbook_anim_extra_initial_state }
        else
          v.flipbook_anim_extra_current_states = { extra = "default" }
        end
      end

      local first = next(v.config.center.flipbook_anim_extra_states)
      if v.config.center.flipbook_anim_extra_states[first].anim then
        v.config.center.flipbook_anim_extra_states = { extra = v.config.center.flipbook_anim_extra_states }
      end

      v.flipbook_anim_extra = {}

      for layer, state in pairs(v.flipbook_anim_extra_current_states) do
        local cache_key = layer .. ":" .. state

        if not v.flipbook_anim_extra_cache[cache_key] then
          local anim = v.config.center.flipbook_anim_extra_states[layer][state].anim
          v.flipbook_anim_extra_cache[cache_key] = format_flipbook_anim(anim)
        end

        v.flipbook_anim_extra[layer] = v.flipbook_anim_extra_cache[cache_key]
      end
    else
      if not next(v.config.center.flipbook_anim_extra) then
        return                                                                                             -- There's nothing in the animation.
      elseif v.config.center.flipbook_anim_extra[1] and not v.config.center.flipbook_anim_extra[1][1] then -- The animation doesn't give multiple layers.
        v.flipbook_anim_extra = { extra = v.config.center.flipbook_anim_extra }
      else
        v.flipbook_anim_extra = v.config.center.flipbook_anim_extra
      end

      for k, layer in pairs(v.flipbook_anim_extra) do
        if not v.flipbook_anim_extra_cache[k] then
          v.flipbook_anim_extra_cache[k] = format_flipbook_anim(layer)
        end
        v.flipbook_anim_extra[k] = v.flipbook_anim_extra_cache[k]
      end
    end

    if v.flipbook_anim_extra then
      for k, layer in pairs(v.flipbook_anim_extra) do
        local loop = v.config.center.flipbook_anim_extra_states and v.config.center.flipbook_anim_extra_states[k]
            and v.flipbook_anim_extra_current_states and v.flipbook_anim_extra_current_states[k]
            and v.config.center.flipbook_anim_extra_states[k][v.flipbook_anim_extra_current_states[k]]
            and v.config.center.flipbook_anim_extra_states[k][v.flipbook_anim_extra_current_states[k]].loop
        if loop == nil then loop = true end -- IMPORTANT: DO NOT SIMPLIFY TO not loop, AS FALSE IS ALLOWED.

        if not v.flipbook_anim_extra_t then v.flipbook_anim_extra_t = {} end
        if not v.flipbook_anim_extra_t[k] then
          v.flipbook_anim_extra_t[k] = 0
        end
        v.flipbook_anim_extra_t[k] = v.flipbook_anim_extra_t[k] + dt

        if not layer.length then
          layer.length = 0
          for _, frame in ipairs(layer) do
            layer.length = layer.length + (frame.t or 0)
          end
        end

        if not loop and v.flipbook_anim_extra_t[k] >= layer.length then
          local continuation = v.config.center.flipbook_anim_extra_states[k][v.flipbook_anim_extra_current_states[k]].continuation
          if continuation then
            v.flipbook_anim_extra_current_states[k] = continuation
            v.flipbook_anim_extra_t[k] = 0
            handle_flipbook_anim_extra(v, 0)
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
        if layer[ix].atlas then
          v.flipbook_pos_extra[k].atlas = layer[ix].atlas
        end
      end
    end
  end
end

function Card:flipbook_set_anim_state(state, dont_reset_t)
  local center = self.config.center
  local states = center.flipbook_anim_states
  if not states then return end

  if state == nil then state = "default" end
  self.flipbook_anim_current_state = state

  if not self.flipbook_anim_t or not dont_reset_t then self.flipbook_anim_t = 0 end

  if not states[state] or not states[state].anim then return end
  local frame = format_flipbook_anim(states[state].anim)[flipbook_index_into_anim(states[state].anim, self.flipbook_anim_t)]
  if not frame then return end

  self.children.center:set_sprite_pos { x = frame.x or 0, y = frame.y or 0 }
  self.children.center:flipbook_set_atlas(frame.atlas or states[state].atlas or center.atlas)
end

function Card:flipbook_set_anim_extra_state(state, layer, dont_reset_t)
  local center = self.config.center
  local states = center.flipbook_anim_extra_states

  local first = next(states)
  if first and states[first].anim then
    states = { extra = states }
  end

  if layer == nil then layer = "extra" end
  if state == nil then state = "default" end

  if not self.flipbook_anim_extra_current_states then
    self.flipbook_anim_extra_current_states = {}
  end
  self.flipbook_anim_extra_current_states[layer] = state

  if not self.flipbook_anim_extra_t then
    self.flipbook_anim_extra_t = {}
  end

  if not dont_reset_t then
    self.flipbook_anim_extra_t[layer] = 0
  end

  local state_thing = states[layer] and states[layer][state]
  if not state_thing or not state_thing.anim then return end

  local frame = format_flipbook_anim(state_thing.anim)[flipbook_index_into_anim(state_thing.anim, self.flipbook_anim_extra_t[layer])]
  if not frame then return end

  if not self.flipbook_pos_extra then
    self.flipbook_pos_extra = {}
  end
  if not self.flipbook_pos_extra[layer] then
    self.flipbook_pos_extra[layer] = {}
  end

  self.flipbook_pos_extra[layer].x = frame.x or 0
  self.flipbook_pos_extra[layer].y = frame.y or 0
  self.flipbook_pos_extra[layer].atlas = frame.atlas or state_thing.atlas or center.atlas
end

function SMODS.Center:flipbook_set_anim_state(state, dont_reset_t)
  local center = self
  local states = center.flipbook_anim_states
  if not states then return end

  if state == nil then state = "default" end

  for _, v in pairs(G.MOVEABLES or {}) do
    if v and v.config and v.config.center and v.config.center.key == center.key then
      v.flipbook_anim_current_state = state

      if not v.flipbook_anim_t then
        v.flipbook_anim_t = 0
      end

      if not dont_reset_t then
        v.flipbook_anim_t = 0
      end

      if not states[state] or not states[state].anim then return end
      local frame = format_flipbook_anim(states[state].anim)[flipbook_index_into_anim(states[state].anim, v.flipbook_anim_t)]
      if frame then
        v.children.center:set_sprite_pos { x = frame.x or 0, y = frame.y or 0 }
        v.children.center:flipbook_set_atlas(frame.atlas or states[state].atlas or center.atlas)
      end
    end
  end
end

function SMODS.Center:flipbook_set_anim_extra_state(state, layer, dont_reset_t, change_center)
  local states = self.flipbook_anim_extra_states
  if not states then return end

  local first = next(states)
  if first and states[first].anim then
    states = { extra = states }
  end

  if layer == nil then layer = "extra" end
  if state == nil then state = "default" end

  if change_center then
    self.flipbook_anim_extra_initial_states = self.flipbook_anim_extra_initial_states or {}
    self.flipbook_anim_extra_initial_states[layer] = state
  end

  for _, v in pairs(G.MOVEABLES or {}) do
    if v and v.config and v.config.center and v.config.center.key == self.key then
      if not v.flipbook_anim_extra_current_states then
        v.flipbook_anim_extra_current_states = {}
      end
      v.flipbook_anim_extra_current_states[layer] = state

      if not v.flipbook_anim_extra_t then
        v.flipbook_anim_extra_t = {}
      end

      if not dont_reset_t then
        v.flipbook_anim_extra_t[layer] = 0
      end

      local state_thing = states[layer] and states[layer][state]
      if state_thing and state_thing.anim then
        local frame = format_flipbook_anim(state_thing.anim)[flipbook_index_into_anim(state_thing.anim, v.flipbook_anim_extra_t[layer])]

        if frame then
          v.flipbook_pos_extra = v.flipbook_pos_extra or {}
          v.flipbook_pos_extra[layer] = v.flipbook_pos_extra[layer] or {}

          v.flipbook_pos_extra[layer].x = frame.x or 0
          v.flipbook_pos_extra[layer].y = frame.y or 0
          v.flipbook_pos_extra[layer].atlas =
              frame.atlas or state_thing.atlas or self.atlas
        end
      end
    end
  end
end

flipbook_index_into_anim = function(anim, t)
  local length = 0
  for _, frame in ipairs(anim) do
    length = length + (frame.t or 0)
  end

  local ix = 1
  local tally = 0
  for i, frame in ipairs(anim) do
    tally = tally + (frame.t or 0)
    if tally > t then
      ix = i
      break
    end
  end

  return ix
end
