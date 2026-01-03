import PreferenceCheckbox from "discourse/components/preference-checkbox";

const PreferencesEmailEcho = <template>
  <PreferenceCheckbox
    @labelKey="user.email_echo_enabled"
    @checked={{@outletArgs.model.user_option.email_echo_enabled}}
    data-setting-name="email-echo-enabled"
    class="pref-email-echo"
  />
</template>;

export default PreferencesEmailEcho;
