<?php

use App\Http\Controllers\IADetectionController;
use App\Http\Controllers\AdminController;
use App\Http\Controllers\ProblemController;
use Illuminate\Support\Facades\Route;

Route::post('/ia/detections', [IADetectionController::class, 'store']);
Route::post('/ia/detections/bulk', [IADetectionController::class, 'storeBulk']);
Route::get('/zones', [AdminController::class, 'zones']);
Route::get('/intervenant/assignments', [ProblemController::class, 'intervenantAssignments']);
