<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.4" tiledversion="1.4.2" name="blocks" tilewidth="16" tileheight="16" tilecount="72" columns="9">
 <image source="blocks.tmx" width="144" height="128"/>
 <tile id="0" type="block"/>
 <tile id="1" type="block"/>
 <tile id="2" type="block"/>
 <tile id="3" type="block"/>
 <tile id="4" type="block"/>
 <tile id="5" type="block"/>
 <tile id="6" type="block"/>
 <tile id="7" type="block"/>
 <tile id="8" type="block"/>
 <tile id="9" type="animationblock">
  <properties>
   <property name="animation_activation">initialTrigger: 0
triggerInterval: 600
frameInterval: 6</property>
   <property name="animation_id" value="caged_ball"/>
  </properties>
  <animation>
   <frame tileid="9" duration="100"/>
   <frame tileid="11" duration="100"/>
   <frame tileid="13" duration="100"/>
   <frame tileid="15" duration="100"/>
   <frame tileid="15" duration="100"/>
   <frame tileid="13" duration="100"/>
   <frame tileid="11" duration="100"/>
  </animation>
 </tile>
 <tile id="10" type="animationblock">
  <properties>
   <property name="animation_id" value="caged_ball"/>
  </properties>
  <animation>
   <frame tileid="10" duration="100"/>
   <frame tileid="12" duration="100"/>
   <frame tileid="14" duration="100"/>
   <frame tileid="16" duration="100"/>
   <frame tileid="16" duration="100"/>
   <frame tileid="14" duration="100"/>
   <frame tileid="12" duration="100"/>
  </animation>
 </tile>
 <tile id="11" type="block"/>
 <tile id="12" type="block"/>
 <tile id="13" type="block"/>
 <tile id="14" type="block"/>
 <tile id="15" type="block"/>
 <tile id="16" type="block"/>
 <tile id="17" type="block"/>
 <tile id="18" type="animationblock">
  <properties>
   <property name="animation_id" value="caged_ball"/>
  </properties>
  <animation>
   <frame tileid="18" duration="100"/>
   <frame tileid="20" duration="100"/>
   <frame tileid="22" duration="100"/>
   <frame tileid="24" duration="100"/>
   <frame tileid="24" duration="100"/>
   <frame tileid="22" duration="100"/>
   <frame tileid="20" duration="100"/>
  </animation>
 </tile>
 <tile id="19" type="animationblock">
  <properties>
   <property name="animation_id" value="caged_ball"/>
  </properties>
  <animation>
   <frame tileid="19" duration="100"/>
   <frame tileid="21" duration="100"/>
   <frame tileid="23" duration="100"/>
   <frame tileid="25" duration="100"/>
   <frame tileid="25" duration="100"/>
   <frame tileid="23" duration="100"/>
   <frame tileid="21" duration="100"/>
  </animation>
 </tile>
 <tile id="20" type="block"/>
 <tile id="21" type="block"/>
 <tile id="22" type="block"/>
 <tile id="23" type="block"/>
 <tile id="24" type="block"/>
 <tile id="25" type="block"/>
 <tile id="26" type="block"/>
 <tile id="27" type="animationblock">
  <properties>
   <property name="animation_activation">initialTrigger: 1
triggerInterval: 600
frameInterval: 6</property>
   <property name="animation_frame_offset" type="int" value="3"/>
   <property name="animation_id" value="caged_ball2"/>
  </properties>
  <animation>
   <frame tileid="27" duration="100"/>
   <frame tileid="29" duration="100"/>
   <frame tileid="31" duration="100"/>
   <frame tileid="33" duration="100"/>
   <frame tileid="33" duration="100"/>
   <frame tileid="31" duration="100"/>
   <frame tileid="29" duration="100"/>
   <frame tileid="27" duration="100"/>
  </animation>
 </tile>
 <tile id="28" type="animationblock">
  <properties>
   <property name="animation_id" value="caged_ball2"/>
  </properties>
  <animation>
   <frame tileid="28" duration="100"/>
   <frame tileid="30" duration="100"/>
   <frame tileid="32" duration="100"/>
   <frame tileid="34" duration="100"/>
   <frame tileid="34" duration="100"/>
   <frame tileid="32" duration="100"/>
   <frame tileid="30" duration="100"/>
   <frame tileid="28" duration="100"/>
  </animation>
 </tile>
 <tile id="29" type="block"/>
 <tile id="30" type="block"/>
 <tile id="31" type="block"/>
 <tile id="32" type="block"/>
 <tile id="33" type="block"/>
 <tile id="34" type="block"/>
 <tile id="35" type="block"/>
 <tile id="36" type="animationblock">
  <properties>
   <property name="animation_id" value="caged_ball2"/>
  </properties>
  <animation>
   <frame tileid="36" duration="100"/>
   <frame tileid="38" duration="100"/>
   <frame tileid="40" duration="100"/>
   <frame tileid="42" duration="100"/>
   <frame tileid="42" duration="100"/>
   <frame tileid="40" duration="100"/>
   <frame tileid="38" duration="100"/>
   <frame tileid="36" duration="100"/>
  </animation>
 </tile>
 <tile id="37" type="animationblock">
  <properties>
   <property name="animation_id" value="caged_ball2"/>
  </properties>
  <animation>
   <frame tileid="37" duration="100"/>
   <frame tileid="39" duration="100"/>
   <frame tileid="41" duration="100"/>
   <frame tileid="43" duration="100"/>
   <frame tileid="43" duration="100"/>
   <frame tileid="41" duration="100"/>
   <frame tileid="39" duration="100"/>
   <frame tileid="37" duration="100"/>
  </animation>
 </tile>
 <tile id="38" type="block"/>
 <tile id="39" type="block"/>
 <tile id="40" type="block"/>
 <tile id="41" type="block"/>
 <tile id="42" type="block"/>
 <tile id="43" type="block"/>
 <tile id="44" type="block"/>
 <tile id="45" type="animationblock">
  <properties>
   <property name="animation_activation">initialTrigger: 2
triggerInterval: 600
frameInterval: 6</property>
   <property name="animation_id" value="cyclops"/>
  </properties>
  <animation>
   <frame tileid="45" duration="100"/>
   <frame tileid="47" duration="100"/>
   <frame tileid="49" duration="100"/>
   <frame tileid="51" duration="100"/>
   <frame tileid="49" duration="100"/>
   <frame tileid="47" duration="100"/>
  </animation>
 </tile>
 <tile id="46" type="animationblock">
  <properties>
   <property name="animation_id" value="cyclops"/>
  </properties>
  <animation>
   <frame tileid="46" duration="100"/>
   <frame tileid="48" duration="100"/>
   <frame tileid="50" duration="100"/>
   <frame tileid="52" duration="100"/>
   <frame tileid="50" duration="100"/>
   <frame tileid="48" duration="100"/>
  </animation>
 </tile>
 <tile id="47" type="block"/>
 <tile id="48" type="block"/>
 <tile id="49" type="block"/>
 <tile id="50" type="block"/>
 <tile id="51" type="block"/>
 <tile id="52" type="block"/>
 <tile id="53" type="block"/>
 <tile id="54" type="animationblock">
  <properties>
   <property name="animation_id" value="cyclops"/>
  </properties>
  <animation>
   <frame tileid="54" duration="100"/>
   <frame tileid="56" duration="100"/>
   <frame tileid="58" duration="100"/>
   <frame tileid="60" duration="100"/>
   <frame tileid="58" duration="100"/>
   <frame tileid="56" duration="100"/>
  </animation>
 </tile>
 <tile id="55" type="animationblock">
  <properties>
   <property name="animation_id" value="cyclops"/>
  </properties>
  <animation>
   <frame tileid="55" duration="100"/>
   <frame tileid="57" duration="100"/>
   <frame tileid="59" duration="100"/>
   <frame tileid="61" duration="100"/>
   <frame tileid="59" duration="100"/>
   <frame tileid="57" duration="100"/>
  </animation>
 </tile>
 <tile id="56" type="block"/>
 <tile id="57" type="block"/>
 <tile id="58" type="block"/>
 <tile id="59" type="block"/>
 <tile id="60" type="block"/>
 <tile id="61" type="block"/>
 <tile id="62" type="block"/>
 <tile id="63" type="animationblock">
  <properties>
   <property name="animation_activation">initialTrigger: 1
triggerInterval: 600
frameInterval: 6</property>
   <property name="animation_frame_interval" type="int" value="2"/>
   <property name="animation_id" value="water"/>
   <property name="animation_scheduler" value="scroll_x"/>
  </properties>
  <animation>
   <frame tileid="63" duration="100"/>
   <frame tileid="64" duration="100"/>
   <frame tileid="65" duration="100"/>
   <frame tileid="66" duration="100"/>
  </animation>
 </tile>
 <tile id="64" type="block"/>
 <tile id="65" type="block"/>
 <tile id="66" type="block"/>
 <tile id="67" type="animationblock">
  <properties>
   <property name="animation_activation">initialTrigger: 1
triggerInterval: 600
frameInterval: 6</property>
   <property name="animation_frame_interval" type="int" value="4"/>
   <property name="animation_frame_offset" type="int" value="8"/>
   <property name="animation_id" value="water_slow"/>
   <property name="animation_scheduler" value="scroll_x"/>
  </properties>
  <animation>
   <frame tileid="67" duration="200"/>
   <frame tileid="68" duration="200"/>
   <frame tileid="69" duration="200"/>
   <frame tileid="70" duration="200"/>
  </animation>
 </tile>
 <tile id="68" type="block"/>
 <tile id="69" type="block"/>
 <tile id="70" type="block"/>
 <tile id="71" type="block"/>
</tileset>
