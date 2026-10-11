# Dependency.Tests.ps1

Describe 'Dependency resolution'

function Test_Dependency_pulls_in_missing_dependency {
    $sel = Resolve-AgentSkillsSelection -SkillIds @('react-best-practices')
    Assert-Contains $sel.Resolved 'react-best-practices'
    Assert-Contains $sel.Resolved 'frontend-architecture'
    Assert-Contains $sel.AddedDependencies 'frontend-architecture'
}

function Test_Dependency_already_present_is_not_added_twice {
    $sel = Resolve-AgentSkillsSelection -SkillIds @('react-best-practices', 'frontend-architecture')
    Assert-Equal 0 @($sel.AddedDependencies).Count 'Explicitly requested dependency should not be reported as added.'
}

function Test_Dependency_unknown_id_throws {
    Assert-Throws { Resolve-AgentSkillsSelection -SkillIds @('nope-not-real') } 'Unknown skill id'
}

function Test_Dependency_transitive_closure {
    # integration-testing depends on unit-testing.
    $sel = Resolve-AgentSkillsSelection -SkillIds @('integration-testing')
    Assert-Contains $sel.Resolved 'integration-testing'
    Assert-Contains $sel.Resolved 'unit-testing'
}

function Test_Dependency_all_registry_graphs_are_acyclic {
    $reg = Get-AgentSkillsRegistry
    foreach ($s in @($reg.Skills.skills)) {
        Assert-NoThrow { Resolve-AgentSkillsSelection -SkillIds @($s.id) -Registry $reg } "Cycle detected at '$($s.id)'."
    }
}
