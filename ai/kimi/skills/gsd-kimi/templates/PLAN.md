<?xml version="1.0"?>
<plan>
  <metadata>
    <phase>{N}</phase>
    <plan>{M}</plan>
    <name>{Plan Name}</name>
    <estimated_hours>{X}</estimated_hours>
    <created>{date}</created>
  </metadata>
  
  <overview>
    {Brief description of what this plan accomplishes}
  </overview>
  
  <prerequisites>
    <item>{Prerequisite 1}</item>
    <item>{Prerequisite 2}</item>
  </prerequisites>
  
  <context>
    {Relevant context from CONTEXT.md}
    {Any important background}
  </context>
  
  <tasks>
    <task type="auto" priority="1">
      <id>{phase}-{plan}-001</id>
      <name>{Task Name}</name>
      <files>{file paths}</files>
      <action>
{Detailed implementation instructions}
{Use markdown formatting}
{Include code examples if helpful}
      </action>
      <verify>
{How to verify this task}
{Include test commands}
      </verify>
      <done>
{Definition of done}
      </done>
    </task>
    
    <!-- Additional tasks... -->
    
  </tasks>
  
  <verification>
    <overall>
{How to verify the entire plan}
    </overall>
    <acceptance_criteria>
      <criterion id="1">{Criterion 1}</criterion>
      <criterion id="2">{Criterion 2}</criterion>
    </acceptance_criteria>
    <test_commands>
{Commands to run for verification}
    </test_commands>
  </verification>
  
  <notes>
{Any additional notes}
  </notes>
</plan>
