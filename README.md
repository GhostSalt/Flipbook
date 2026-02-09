# Flipbook — Balatro Animation API
## Introduction
Welcome to Flipbook! This API mod allows you to animate the Jokers, Consumables, Vouchers, etc. in your Balatro mods.

If you only need simple animation, then SMODS already has tools for that. This mod adds more in-depth animation features, such as individual frame delays, frame ranges and animation states.

## Getting Started With Animation
Here is a simple animation for a Joker that changes between three sprites on 1 second intervals:
```
flipbook_anim = {
  { x = 0, y = 0, t = 1 },
  { x = 1, y = 0, t = 1 },
  { x = 2, y = 0, t = 1 }
}
```
`x` and `y` work similarly to `pos`. `t` is how long the frame is shown for, in seconds.

This is put on the Joker's object definition, alongside its other variables like `key` and `pos`. You can also animate Centers from the vanilla game or from other mods by using SMODS' `take_ownership` function, or by other means of adding code to Centers.

## Ranges
The above animation can be simplified using the `xrange` field:
```
flipbook_anim = {
  { xrange = { first = 0, last = 2 }, y = 0, t = 1 }
}
```
If your animation has lots of frames within a range of x locations, `xrange` is a shorthand that allows you to code that in 1 line. `first` is the location in the range that will be shown first; `last` will be shown last.

`t` is the time that each frame individually will be shown, so this animation will last a total of 1 + 1 + 1 = 3 seconds.

You can also use `yrange`:
```
flipbook_anim = {
  { xrange = { first = 0, last = 2 }, yrange = { first = 0, last = 2 }, t = 1 }
}
```
This works similarly to `xrange`, but operates on `y` values instead. As shown in the code above, these two fields can be used together to save a lot of lines of code.

Note that you cannot currently specify individual frame durations when using `xrange` or `yrange`; `t` applies to all frames within range.

When using `xrange` and `yrange` together, frames are displayed in reading order (left to right, top to bottom). Here's what the above code would look like without using `xrange` or `yrange`:
```
flipbook_anim = {
  { x = 0, y = 0, t = 1 },
  { x = 1, y = 0, t = 1 },
  { x = 2, y = 0, t = 1 },
  { x = 0, y = 1, t = 1 },
  { x = 1, y = 1, t = 1 },
  { x = 2, y = 1, t = 1 },
  { x = 0, y = 2, t = 1 },
  { x = 1, y = 2, t = 1 },
  { x = 2, y = 2, t = 1 }
}
```
If `first` is less than `last`, the range will be in ascending order. However, if `first` is greater than `last`, the range will be in descending order, which may be useful for reversing animations:
```
flipbook_anim = {
  { xrange = { first = 2, last = 0 }, yrange = { first = 2, last = 0 }, t = 1 }
}
```
This is equivalent to:
```
flipbook_anim = {
  { x = 2, y = 2, t = 1 },
  { x = 1, y = 2, t = 1 },
  { x = 0, y = 2, t = 1 },
  { x = 2, y = 1, t = 1 },
  { x = 1, y = 1, t = 1 },
  { x = 0, y = 1, t = 1 },
  { x = 2, y = 0, t = 1 },
  { x = 1, y = 0, t = 1 },
  { x = 0, y = 0, t = 1 },
}
```

## Layers
The field `flipbook_pos_extra` allows you to specify multiple layers for your object. Below is an example of a Joker with two layers:
```
atlas = "example",
pos = { x = 0, y = 0 },
flipbook_pos_extra = { x = 1, y = 1, atlas = "foo" }
```
The location in `pos` is always the bottom layer; any `flipbook_pos_extra`s are rendered on top of it.

Each extra layer can optionally use a different Atlas from the bottom layer — if no Atlas is provided, they default to the bottom layer's Atlas.

If an object with multiple layers has an edition, all layers are rendered with the edition automatically.

You can have more than two layers:
```
atlas = "example",
pos = { x = 0, y = 0 },
flipbook_pos_extra = {
  top_layer = { x = 1, y = 1 }, -- Defaults to atlas "example"
  middle_layer = { x = 2, y = 3, atlas = "bar" }, -- Uses atlas "bar"
  bottom_layer = { x = 5, y = 8, atlas = "baz" }, -- Uses atlas "baz"
}
```
The above code specifies four layers. Each layer needs to have a key, but the keys can be whatever you want them to be (as long as they are valid in Lua).

In the example where the `x`, `y` and `atlas` are given directly without a key, the key defaults to `extra`.

The first layer provided goes on top of the others, followed by the second, then the third, until the last layer is reached. The bottom layer goes under all other layers, but over the base layer. (In this case, `top_layer` goes over `middle_layer`, which goes over `bottom_layer`, which goes over the location provided by `pos`.)

## Animating Layers

Just like the base layer, extra layers can be animated. This is largely the same, but has a couple differences.

When animating extra layers, you don't need to specify `flipbook_pos_extra` (unless specifying a layer's Atlas), as Flipbook changes it while animating.

If you're only animating one extra layer, the syntax is the same.
```
flipbook_anim_extra = {
  { xrange = { first = 0, last = 2 }, yrange = { first = 0, last = 2 }, t = 1 }
}
```
Ranges function the same as they did with the base layer.

When animating multiple layers, each animation needs to have a key associated with it, so Flipbook knows which layer it belongs to. Here's an example of a Joker with 3 extra layers being animated:
```
flipbook_anim_extra = {
  foo = { { xrange = { first = 0, last = 2 }, yrange = { first = 0, last = 2 }, t = 1 } },
  bar = { { x = 0, y = 3, t = 0.333 }, { x = 1, y = 3, t = 0.2 } },
  baz = { { x = 2, y = 3, t = 0.111 }, { x = 3, y = 3, t = 0.1 } }
}
```
In the example where the animation is given directly without a key, the key defaults to `extra`.

Like the `flipbook_pos_extra`, the top layer is the first in the table, and the bottom layer is the last (so here, `foo` renders over `bar`, which renders over `baz`).

Extra layer animations don't have to synchronise with the base layer or each other; layer animations run independently from each other.

## Animation States
Suppose we have a Joker called Gary. Gary acts normally most of the time, while you have him. However, Gary doesn't like Spades. When playing a Spade, he'll get angry for a few seconds, before calming down and acting normally again. Gary is also deathly allergic to steel; when playing a Steel card, he'll keel over and die, becoming unresponsive forever.

How would we implement Gary? Below is an example, showing how animation states can be made with Flipbook.
```
flipbok_anim_states = {
  normal = { anim = { { x = 0, y = 0, t = 1 }, { x = 1, y = 0, t = 1 } } },
  angry = { anim = { { x = 2, y = 0, t = 0.5 }, { x = 3, y = 0, t = 10 } }, loop = false, continuation = "normal" },
  dead = { anim = { { x = 4, y = 0, t = 1 } }, loop = false }
},
flipbook_anim_current_state = "normal"
```
From Gary's description, we know that he can be in one of three states: `normal`, `angry` or `dead`. An animation state is defined for each state Gary can be in.

We also know that Gary acts normally most of the time, so his default state (assigned to `flipbook_anim_current_state`) is `"normal"`. (If a starting state isn't provided, "default" is chosen. << I'M NOT SURE IF THIS WORKS RIGHT NOW)

Every animation state needs to define an `anim`, which are like the animations we've written before.

By default, when an animation state is finished, it starts again. If we don't want it to loop, its `loop` parameter can be set to `false`. `normal` should loop, but `angry` should not, so their `loop` parameters are `true` (default value) and `false` respectively.

It doesn't matter if `dead` is looping or not, but if your animation has only one frame, you should generally choose no looping for performance optimisation, which is why it's set to not loop here.

If an animation doesn't loop, it can also be given a `continuation`, which tells Flipbook which state to go to next. Since we want Gary to become `normal` after being `angry`, `angry` has a `continuation` of `"normal"`.

Now we have Gary's animation states set up, we can change between them using the function `flipbook_set_anim_state`. This function can either be called on a `Card`, an `SMODS.Center` or on its own, with `center` as the first parameter.
```
Card:flipbook_set_anim_state(state, dont_reset_t)
SMODS.Center:flipbook_set_anim_state(state, dont_reset_t)
flipbook_set_anim_state(center, state, dont_reset_t)
```
`state` (required) is the state you want to change to. `dont_reset_t` (optional) states whether or not the animation transitioned to should be restarted — `true` if the new animation should not start over, `false` or `nil` if it should.

## Animation States With Extra Layers
Gary has a new pet bird called Macy! They'll both be sharing the same cardspace now.

Macy sleeps most of the time, but is woken up when David gets angry. After a while, she'll go back to sleep.

Here's how that would be implemented:
```
flipbok_anim_states = {
  normal = { anim = { { x = 0, y = 0, t = 1 }, { x = 1, y = 0, t = 1 } } },
  angry = { anim = { { x = 2, y = 0, t = 0.5 }, { x = 3, y = 0, t = 10 } }, loop = false, continuation = "normal" },
  dead = { anim = { { x = 4, y = 0, t = 1 } }, loop = false }
},
flipbook_anim_current_state = "normal",
flipbook_anim_extra_states = {
  eepy = { anim = { { x = 5, y = 0, t = 1 }, loop = false } },
  awake = { anim = { { xrange = { first = 6, last = 8 }, y = 0, t = 10 } }, loop = false, continuation = "eepy" }
},
flipbook_anim_extra_current_state = "normal"
```
With one layer, this looks similar to Gary's code. If Gary were to get a statue of an iguana (he calls it David), the code would look like this.
```
flipbok_anim_states = {
  normal = { anim = { { x = 0, y = 0, t = 1 }, { x = 1, y = 0, t = 1 } } },
  angry = { anim = { { x = 2, y = 0, t = 0.5 }, { x = 3, y = 0, t = 10 } }, loop = false, continuation = "normal" },
  dead = { anim = { { x = 4, y = 0, t = 1 } }, loop = false }
},
flipbook_anim_current_state = "normal",
flipbook_anim_extra_states = {
  macy = {
    eepy = { anim = { { x = 5, y = 0, t = 1 }, loop = false } },
    awake = { anim = { { xrange = { first = 6, last = 8 }, y = 0, t = 10 } }, loop = false, continuation = "eepy" }
  },
  david = {
    existing = { anim = { { x = 0, y = 1, t = 1 } }, loop = false }
  }
},
flipbook_anim_extra_current_states = { macy = "eepy", david = "existing" }
```
Since we now have multiple extra layers, each animation state list needs its own key — in this case, `macy` and `david`.

Note that `flipbook_anim_extra_current_state` was changed to `flipbook_anim_extra_current_states`, to specify starting states for all of the extra layers.

We can change each layer's states using the following functions:
```
Card:flipbook_set_anim_extra_state(state, layer, dont_reset_t)
SMODS.Center:flipbook_set_anim_extra_state(state, layer, dont_reset_t)
flipbook_set_anim_extra_state(center, state, layer, dont_reset_t)
```
The `layer` parameter is needed for Flipbook to know which layer you want to change the state of. If left as `nil`, it defaults to `extra`. The other parameters work similarly to `flipbook_set_anim_state`.

(If you have any questions about this README or about the mod, ask `ghost12salt` on Discord.)
