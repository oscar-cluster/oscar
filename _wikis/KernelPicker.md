---
layout: wiki
title: KernelPicker
meta: 
permalink: "wiki/KernelPicker"
category: wiki
---
<!-- Name: KernelPicker -->
<!-- Version: 11 -->
<!-- Author: bli -->

# Kernel Picker

*KernelPicker* is responsible for installing and setting a kernel on the node
images. 

* *Note*: this page is an architecture draft of *KernelPicker*. It has not been yet implemented.

## Functionnal outline

=== Current === 

The current *KernelPicker* consists of one command which does all work at one time (see [attachment:kp_funct_old.svg]).

### New

See [attachment:kp_funct.svg]

On the figure, a _boot config_ is an association between:


1. a kernel,

2. some boot parameters,

3. a deployment method,

4. a node set.

## Relational outline

See [attachment:oscar_oda.svg]

New tables (needed for *KernelPicker*) are emphasized.

## Components Architecture

### Current

Current *KernelPicker* does not use any OSCAR component nor helper programs. All the work of selecting a kernel, listing the SystemImager images, copying the kernel to the image, etc., is done through basic shell commands, such as `ls`, `cp`, `mv`, etc.

See [attachment:kp_archi_old.svg]

### New

The new architecture follows the OCA rules, _i.e._:

* *KernelPicker* provides a functionnality: it is a _framework_,

* functionalities can be handled in different ways through different _components_.

*KernelPicker* uses other OSCAR frameworks:

* if kernel is installed from a package, the *PackMan/Depman* framework is used to get the list of available kernel and select the package,

* then the kernel is deployed using the deployment framework. By now, it does not exist as we use only *SystemImager*. Yet, we will begin to describe an API for this framework.

See [attachment:kp_archi.svg]

## Class Diagram

See [attachment:kp_obj.svg]

Following Classes should be into ODA package, as they only deal with database objects:

* `BootConfig` and `BootConfigFactory`,

* `BootMethod` and `BootMethodFactory`,

* `BootKernel` and `BootKernelFactory`.

The class *KernelPicker* is the highest level class, which could be accessed by CLI, GUI or any other interface.

* The method `KernelPicker::getKernelPackageList` take an optionnal list of capacities in argument. These capacities allows to filter the list of package returned by the method. They are constants defined as `KernelPicker::KP_CAPS_*`.

* The method `BootMethodFactory::getBootMethod` returns all `BootMethod` objects whose boot loader is `loader`, amongst constants defined as `BM_*`.
