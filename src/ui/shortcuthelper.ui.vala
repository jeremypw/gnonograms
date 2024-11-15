namespace Gnonograms {
    const string shortcuthelper_ui = """
<interface>
  <object class="GtkShortcutsWindow" id="shortcuts-window">
    <property name="modal">1</property>
    <child>
      <object class="GtkShortcutsSection">
        <property name="section-name">Keyboard Shortcuts</property>
        <property name="max-height">15</property>
        <child>
          <object class="GtkShortcutsGroup">
            <property name="title" translatable="yes">Drawing</property>
            <child>
              <object class="GtkShortcutsShortcut">
                <property name="accelerator">F</property>
                <property name="title" translatable="yes">Paint FILLED</property>
              </object>
            </child>
           <child>
            <object class="GtkShortcutsShortcut">
              <property name="accelerator">E</property>
              <property name="title" translatable="yes">Paint EMPTY</property>
            </object>
           </child>
           <child>
            <object class="GtkShortcutsShortcut">
              <property name="accelerator">X</property>
              <property name="title" translatable="yes">Paint UNKNOWN</property>
            </object>
           </child>
           <child>
            <object class="GtkShortcutsShortcut">
              <property name="accelerator">Left Right Up Down</property>
              <property name="title" translatable="yes">Move cursor</property>
            </object>
           </child>
          </object>
        </child>
        <child>
          <object class="GtkShortcutsGroup">
            <property name="title" translatable="yes">Game</property>
            <child>
              <object class="GtkShortcutsShortcut">
                <property name="accelerator">&lt;Ctrl&gt;N &lt;Ctrl&gt;3</property>
                <property name="title" translatable="yes">Generate new game</property>
              </object>
            </child>
            <child>
              <object class="GtkShortcutsShortcut">
                <property name="accelerator">&lt;Ctrl&gt;H F9</property>
                <property name="title" translatable="yes">Hint</property>
              </object>
            </child>
            <child>
              <object class="GtkShortcutsShortcut">
                <property name="accelerator">&lt;Ctrl&gt;R F5</property>
                <property name="title" translatable="yes">Restart current game</property>
              </object>
            </child>
            <child>
              <object class="GtkShortcutsShortcut">
                <property name="accelerator">&lt;Ctrl&gt;Z</property>
                <property name="title" translatable="yes">Undo last move</property>
              </object>
            </child>
            <child>
              <object class="GtkShortcutsShortcut">
                <property name="accelerator">&lt;Shift&gt;&lt;Ctrl&gt;Z</property>
                <property name="title" translatable="yes">Redo last move</property>
              </object>
            </child>
            <child>
              <object class="GtkShortcutsShortcut">
                <property name="accelerator">F7</property>
                <property name="title" translatable="yes">Check for and remove errors</property>
              </object>
            </child>
            <child>
              <object class="GtkShortcutsShortcut">
                <property name="accelerator">&lt;Ctrl&gt;H F9</property>
                <property name="title" translatable="yes">Hint</property>
              </object>
            </child>
            <child>
              <object class="GtkShortcutsShortcut">
                <property name="accelerator">&lt;Alt&gt;S</property>
                <property name="title" translatable="yes">Solve by computer</property>
              </object>
            </child>
          </object>
        </child>
        <child>
          <object class="GtkShortcutsGroup">
            <property name="title" translatable="yes">Mode</property>
            <child>
              <object class="GtkShortcutsShortcut">
                <property name="accelerator">&lt;Ctrl&gt;1</property>
                <property name="title" translatable="yes">Designing mode</property>
              </object>
            </child>
            <child>
              <object class="GtkShortcutsShortcut">
                <property name="accelerator">&lt;Ctrl&gt;2</property>
                <property name="title" translatable="yes">Solving mode</property>
              </object>
            </child>
          </object>
        </child>
        <child>
          <object class="GtkShortcutsGroup">
            <property name="title" translatable="yes">General</property>
            <child>
              <object class="GtkShortcutsShortcut">
                <property name="accelerator">Menu</property>
                <property name="title" translatable="yes">Show App Menu</property>
              </object>
            </child>
            <child>
              <object class="GtkShortcutsShortcut">
                <property name="accelerator">&lt;Ctrl&gt;P</property>
                <property name="title" translatable="yes">Show Preferences Dialog</property>
              </object>
            </child>
            <child>
              <object class="GtkShortcutsShortcut">
                <property name="accelerator">&lt;Ctrl&gt;K F1</property>
                <property name="title" translatable="yes">Show Keyboard Shortcuts</property>
              </object>
            </child>
          </object>
        </child>
        <child>
          <object class="GtkShortcutsGroup">
            <property name="title" translatable="yes">Files</property>
            <child>
              <object class="GtkShortcutsShortcut">
                <property name="accelerator">&lt;Ctrl&gt;O</property>
                <property name="title" translatable="yes">Load game from a .gno file</property>
              </object>
            </child>
            <child>
              <object class="GtkShortcutsShortcut">
                <property name="accelerator">&lt;Ctrl&gt;S</property>
                <property name="title" translatable="yes">Save game to a .gno file</property>
              </object>
            </child>
            <child>
              <object class="GtkShortcutsShortcut">
                <property name="accelerator">&lt;Ctrl&gt;S</property>
                <property name="title" translatable="yes">Save game to a diffent file</property>
              </object>
            </child>
          </object>
        </child>
      </object>
    </child>
  </object>
</interface>
""";
}
