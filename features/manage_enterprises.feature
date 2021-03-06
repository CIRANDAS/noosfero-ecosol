Feature: manage enterprises
  As a enterprise owner
  I want to manage my enterprises

  Background:
    Given the following users
      | login | name |
      | joaosilva | Joao Silva |
      | mariasilva | Joao Silva |
    And the following enterprise
      | identifier | name | owner |
      | tangerine-dream | Tangerine Dream | joaosilva |
    And feature "display_my_enterprises_on_user_menu" is enabled on environment

  @selenium
  Scenario: seeing my enterprises on menu
    Given I am logged in as "joaosilva"
    Then I should see "My enterprises" link
    When I follow "My enterprises"
    And I follow "Tangerine Dream"
    Then I should be on tangerine-dream's control panel


  @selenium
  Scenario: not show enterprises on menu to a user without enterprises
    Given I am logged in as "mariasilva"
    Then I should not see "My enterprises" link
