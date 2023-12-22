/* Copyright (c) 2016,2020 The Linux Foundation. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 */

<<<<<<<< HEAD:arch/arm64/boot/dts/qcom/msm8909-1gb-qrd-skue.dts
/dts-v1/;

#include "msm8909-qrd-skue.dtsi"

/ {
	qcom,board-id= <0x1000b 0x9>;
};
========
#ifndef MSM_SENSOR_DRIVER_H
#define MSM_SENSOR_DRIVER_H

#include "msm_sensor.h"

int32_t msm_sensor_driver_probe(void *setting,
	struct msm_sensor_info_t *probed_info, char *entity_name);
>>>>>>>> sonic/master:drivers/media/platform/msm/camera_v2-legacy/sensor/msm_sensor_driver.h

