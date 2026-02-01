package cl.camodev.wosbot.serv.task.constants;

import cl.camodev.wosbot.ot.DTOArea;
import cl.camodev.wosbot.ot.DTOPoint;

public interface ButtonConstants {

    DTOArea LEFT_MENU = new DTOArea(new DTOPoint(6, 535), new DTOPoint(6, 565));
    DTOArea LEFT_MENU_CITY_TAB = new DTOArea(new DTOPoint(90, 260), new DTOPoint(140, 280));
    DTOArea LEFT_MENU_WILDERNESS_TAB = new DTOArea(new DTOPoint(280, 260), new DTOPoint(390, 280));
    DTOArea BOTTOM_MENU_ALLIANCE_BUTTON = new DTOArea(new DTOPoint(512, 1202), new DTOPoint(547, 1230));

    // ========================================================================
    // CHIEF ORDER BUTTON
    // ========================================================================
    DTOArea CHIEF_ORDER_MENU_BUTTON = new DTOArea(new DTOPoint(640, 940), new DTOPoint(680, 970));
    DTOArea CHIEF_ORDER_URGENT_MOBILIZATION_BUTTON = new DTOArea(new DTOPoint(150, 270), new DTOPoint(250, 390));
    DTOArea CHIEF_ORDER_RUSH_JOB_BUTTON = new DTOArea(new DTOPoint(440, 270), new DTOPoint(540, 390));
    DTOArea CHIEF_ORDER_PRODUCTIVITY_DAY_BUTTON = new DTOArea(new DTOPoint(150, 910), new DTOPoint(250, 1030));

}
