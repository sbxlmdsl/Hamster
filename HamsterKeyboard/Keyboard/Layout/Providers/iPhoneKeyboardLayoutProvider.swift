import Foundation
import KeyboardKit

class HamsteriPhoneKeyboardLayoutProvider: iPhoneKeyboardLayoutProvider {
  // MARK: - Overrides

  // 新增九宫格键盘类型
  override func inputRows(for context: KeyboardContext) -> InputSetRows {
    switch context.keyboardType {
    case .alphabetic: return inputSetProvider.alphabeticInputSet.rows
    case .numeric: return inputSetProvider.numericInputSet.rows
    case .symbolic: return inputSetProvider.symbolicInputSet.rows
    case .custom(named: KeyboardConstant.keyboardType.NumberGrid):
      return GridInputSet.numberGrid.rows
    default: return []
    }
  }

  /**
     Get keyboard actions for the `inputs` and `context`.

     Note that `inputs` is an input set and does not contain
     the bottommost space key row, which we therefore append.
     */
  override func actions(for inputs: InputSetRows, context: KeyboardContext) -> KeyboardActionRows {
    let actions = super.actions(for: inputs, context: context)

    // 九宫格布局
    if actions.count == 4, context.isGridViewKeyboardType {
      var result = KeyboardActionRows()
      // 第一行: 添加删除键
      result.append(actions[0] + [.backspace])
      result.append(actions[1])
      // 第三行: 添加符号键
      result.append([.keyboardType(.symbolic)] + actions[2])

      // 第四行: 添加键盘切换键
      if let action = keyboardSwitchActionForBottomRow(for: context) {
        result.append([action] + actions[3] + [keyboardReturnAction(for: context)])
      } else {
        // TODO: 如果不存在键盘切换键, 则手工添加字母键盘
        result.append(
          [.keyboardType(.alphabetic(.lowercased))] + actions[3] + [
            keyboardReturnAction(for: context)
          ])
      }
      return result
    }

    guard isExpectedActionSet(actions) else {
      return actions
    }

    var result = KeyboardActionRows()
    result.append(
      topLeadingActions(for: actions, context: context) + actions[0]
        + topTrailingActions(for: actions, context: context))
    result.append(
      middleLeadingActions(for: actions, context: context) + actions[1]
        + middleTrailingActions(for: actions, context: context))
    result.append(
      lowerLeadingActions(for: actions, context: context) + actions[2]
        + lowerTrailingActions(for: actions, context: context))
    result.append(bottomActions(for: context))
    return result
  }

  /**
     Get the keyboard layout item width of a certain `action`
     for the provided `context`, `row` and row `index`.
     */
  override func itemSizeWidth(
    for action: KeyboardAction, row: Int, index: Int, context: KeyboardContext
  ) -> KeyboardLayoutItemWidth {
    switch action {
    case context.keyboardDictationReplacement: return bottomSystemButtonWidth(for: context)
    case .character:
      return isLastNumericInputRow(row, for: context)
        ? lastSymbolicInputWidth(for: context) : .input
    case .backspace: return lowerSystemButtonWidth(for: context)
    case .keyboardType: return bottomSystemButtonWidth(for: context)
    case .nextKeyboard: return bottomSystemButtonWidth(for: context)
    case .primary: return .percentage(isPortrait(context) ? 0.25 : 0.195)
    case .shift: return lowerSystemButtonWidth(for: context)
    case .custom: return .input
    default: return .available
    }
  }

  // MARK: - iPhone Specific

  /**
     Get the actions of the bottommost space key row.
     */
  override func bottomActions(for context: KeyboardContext) -> KeyboardActions {
    var result = KeyboardActions()

    // 根据键盘类型不同显示不同的切换键: 如数字键盘/字母键盘等切换键
    if let action = keyboardSwitchActionForBottomRow(for: context) {
      result.append(action)
    }

    // 不同输入法切换键
    let needsInputSwitch = context.needsInputModeSwitchKey
    if needsInputSwitch { result.append(.nextKeyboard) }

    // emojis键盘
    // if !needsInputSwitch { result.append(.keyboardType(.emojis)) }

    // 空格
    result.append(.custom(named: KeyboardConstant.CustomButton.Wildcard.rawValue))
    result.append(.space)

    // 根据当前上下文显示不同功能的回车键
    result.append(keyboardReturnAction(for: context))

    return result
  }
}

extension HamsteriPhoneKeyboardLayoutProvider {
  fileprivate func isExpectedActionSet(_ actions: KeyboardActionRows) -> Bool {
    actions.count == 3
  }

  /**
     屏幕方向: 是否纵向
     */
  fileprivate func isPortrait(_ context: KeyboardContext) -> Bool {
    context.interfaceOrientation.isPortrait
  }

  /**
     The width of the last numeric/symbolic row input button.
     */
  fileprivate func lastSymbolicInputWidth(for context: KeyboardContext) -> KeyboardLayoutItemWidth {
    .percentage(0.14)
  }

  /**
     Whether or not a certain row is the last input row in a
     numeric or symbolic keyboard.
     */
  fileprivate func isLastNumericInputRow(_ row: Int, for context: KeyboardContext) -> Bool {
    let isNumeric = context.keyboardType == .numeric
    let isSymbolic = context.keyboardType == .symbolic
    guard isNumeric || isSymbolic else { return false }
    return row == 2  // Index 2 is the "wide keys" row
  }
}

// MARK: - KeyboardContext Extension

extension KeyboardContext {
  /// This function makes the context checks above shorter.
  fileprivate func `is`(_ locale: KeyboardLocale) -> Bool {
    hasKeyboardLocale(locale)
  }

  /// This function makes the context checks above shorter.
  fileprivate func isAlphabetic(_ locale: KeyboardLocale) -> Bool {
    hasKeyboardLocale(locale) && keyboardType.isAlphabetic
  }
}