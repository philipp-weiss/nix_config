{ ... }:
{
  # Home Assistant + the systemd-services it needs. Reachable only via wg0
  # (firewall rule below); see default.nix for the rest of the firewall config.

  # Zigbee USB dongle access for the hass user.
  users.users.hass.extraGroups = [ "dialout" ];

  networking.firewall.interfaces.wg0.allowedTCPPorts = [ 8123 ];

  services.home-assistant = {
    enable = true;
    extraComponents = [
      "zha"
      "homeassistant_hardware"
      "met"
    ];
    config = {
      homeassistant = {
        name = "Home";
        time_zone = "Europe/Berlin";
        unit_system = "metric";
        currency = "EUR";
        country = "DE";
      };
      default_config = {};
      http.server_host = "0.0.0.0";
      rest = [
        {
          resource_template = "https://api.open-meteo.com/v1/forecast?latitude={{ state_attr('zone.home', 'latitude') }}&longitude={{ state_attr('zone.home', 'longitude') }}&past_hours=24&forecast_hours=24&hourly=precipitation&timezone=Europe%2FBerlin";
          scan_interval = 1800;
          sensor = [
            {
              name = "rain_past_24h";
              value_template = "{{ value_json.hourly.precipitation[:24] | sum }}";
              unit_of_measurement = "mm";
            }
            {
              name = "rain_forecast_24h";
              value_template = "{{ value_json.hourly.precipitation[24:48] | sum }}";
              unit_of_measurement = "mm";
            }
          ];
        }
      ];
      automation = [
        {
          id = "garden_watering_start";
          alias = "Garden watering — start";
          description = "Open valve Mon/Wed/Sat at 04:00 during growing season, unless ≥3 mm rain fell in last 24h or is forecast for next 24h (Open-Meteo)";
          triggers = [
            { trigger = "time"; at = "04:00:00"; }
          ];
          conditions = [
            { condition = "time"; weekday = [ "mon" "wed" "sat" ]; }
            { condition = "template"; value_template = "{{ 4 <= now().month <= 10 }}"; }
            { condition = "template"; value_template = "{{ states('sensor.rain_past_24h') | float(99) < 3 }}"; }
            { condition = "template"; value_template = "{{ states('sensor.rain_forecast_24h') | float(99) < 3 }}"; }
          ];
          actions = [
            { action = "switch.turn_on"; target.entity_id = "switch.sonoff_swv"; }
          ];
          mode = "single";
        }
        {
          id = "garden_watering_stop";
          alias = "Garden watering — stop (safety)";
          description = "Always close valve at 06:30, regardless of weekday/season";
          triggers = [
            { trigger = "time"; at = "06:30:00"; }
          ];
          actions = [
            { action = "switch.turn_off"; target.entity_id = "switch.sonoff_swv"; }
          ];
          mode = "single";
        }
      ];
    };
  };
}
