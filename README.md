# 熊德辅助插件

> __自娱自乐，不做任何保证！__  
> 如遇到BUG可反馈至 xhwsd@qq.com 邮箱


## 使用
- 安装`!Libs`插件
- 可选的，安装[SuperMacro](https://ghgo.xyz/https://github.com/xhwsd/SuperMacro/archive/master.zip)插件
- 安装[DaruidBear](https://ghgo.xyz/https://github.com/xhwsd/DaruidBear/archive/master.zip)插件
- 基于插件提供的函数，创建普通或超级宏
- 将宏图标拖至动作条，然后使用宏

> 确保插件最新版本、已适配乌龟服、目录名正确（如删除末尾`-main`、`-master`等）

### 嘲单

> 使用低吼，并大喊

```
/script -- CastSpellByName("低吼")
/script DaruidBear:TauntSingle()
```

逻辑描述：
- 使用该宏需确保低吼在动作条任意位置
- 对目标使用低吼，并大喊


### 嘲群

> 使用挑战咆哮，并大喊

```
/script -- CastSpellByName("挑战咆哮")
/script DaruidBear:TauntGroup()
```


### 拉单

> 单拉一个目标使用

```
/script -- CastSpellByName("槌击")
/script DaruidBear:PullSingle()
```

参数列表：
- `@param dying? integer` 濒死；当剩余生命百分比低于或等于时，将尝试保命；缺省为`30`
- `@param healthy? integer` 健康；当剩余生命百分比高于或等于时，将尝试涨怒气；缺省为`95`

逻辑描述：
- 会在健康、无怒气时使用狂怒
- 会在濒死时使用狂暴回复，并大喊
- 会对目标使用精灵之火


### 拉群

> 群拉多个目标使用

```
/script -- CastSpellByName("挥击")
/script DaruidBear:PullGroup(30, 95)
```

参数列表：
- `@param dying? integer` 濒死；当剩余生命百分比低于或等于时，将尝试保命；缺省为`30`
- `@param healthy? integer` 健康；当剩余生命百分比高于或等于时，将尝试涨怒气；缺省为`95`

逻辑描述：
- 会在健康、无怒气时使用狂怒
- 会在濒死时使用狂暴回复，并大喊
- 会对目标使用精灵之火
- 会对目标使用挫志咆哮
- 会在怒气太多时使用野蛮撕咬


## 命令
- `/xdfz tsms` - 调试模式：开启或关闭调试模式
- `/xdfz tsdj [等级]` - 调试等级：设置或获取调试等级，等级取值范围`1~3`
