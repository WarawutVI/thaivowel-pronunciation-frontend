-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: mysql
-- Generation Time: May 23, 2026 at 12:26 PM
-- Server version: 8.0.45
-- PHP Version: 8.3.26

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `database`
--

-- --------------------------------------------------------

--
-- Table structure for table `user_lesson_progress`
--

CREATE TABLE `user_lesson_progress` (
  `id` int NOT NULL,
  `firebase_uid` varchar(128) NOT NULL,
  `lesson_id` int NOT NULL,
  `is_completed` tinyint(1) DEFAULT '0',
  `best_accuracy` float DEFAULT '0',
  `attempts` int DEFAULT '0',
  `last_practiced_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `user_lesson_progress`
--

INSERT INTO `user_lesson_progress` (`id`, `firebase_uid`, `lesson_id`, `is_completed`, `best_accuracy`, `attempts`, `last_practiced_at`) VALUES
(469, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 1, 1, 0.72, 2, '2026-03-28 00:00:00'),
(470, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 2, 1, 0.75, 2, '2026-03-28 00:00:00'),
(471, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 3, 1, 0.78, 2, '2026-03-30 00:00:00'),
(472, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 4, 1, 0.71, 2, '2026-04-01 00:00:00'),
(473, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 5, 1, 0.73, 2, '2026-04-01 00:00:00'),
(474, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 6, 1, 0.7, 1, '2026-04-01 00:00:00'),
(475, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 7, 1, 0.82, 1, '2026-04-03 00:00:00'),
(476, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 8, 1, 0.76, 1, '2026-04-03 00:00:00'),
(477, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 9, 1, 0.88, 1, '2026-04-03 00:00:00'),
(478, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 10, 1, 0.74, 2, '2026-04-07 00:00:00'),
(479, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 11, 1, 0.72, 1, '2026-04-05 00:00:00'),
(480, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 12, 1, 0.79, 2, '2026-04-07 00:00:00'),
(481, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 13, 1, 0.71, 1, '2026-04-07 00:00:00'),
(482, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 14, 1, 0.77, 2, '2026-04-11 00:00:00'),
(483, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 15, 1, 0.73, 1, '2026-04-09 00:00:00'),
(484, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 16, 1, 0.7, 1, '2026-04-09 00:00:00'),
(485, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 17, 1, 0.75, 2, '2026-04-13 00:00:00'),
(486, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 18, 1, 0.83, 1, '2026-04-11 00:00:00'),
(487, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 19, 1, 0.71, 2, '2026-04-15 00:00:00'),
(488, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 20, 1, 0.75, 2, '2026-04-15 00:00:00'),
(489, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 21, 1, 0.74, 2, '2026-04-17 00:00:00'),
(490, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 22, 1, 0.78, 1, '2026-04-17 00:00:00'),
(491, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 23, 1, 0.72, 1, '2026-04-17 00:00:00'),
(492, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 24, 1, 0.8, 1, '2026-04-19 00:00:00'),
(493, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 25, 1, 0.76, 1, '2026-04-19 00:00:00'),
(494, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 26, 1, 0.73, 2, '2026-04-21 00:00:00'),
(495, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 27, 1, 0.85, 1, '2026-04-21 00:00:00'),
(496, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 28, 1, 0.75, 2, '2026-04-23 00:00:00'),
(497, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 29, 1, 0.71, 1, '2026-04-23 00:00:00'),
(498, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 30, 1, 0.73, 1, '2026-04-23 00:00:00'),
(499, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 31, 1, 0.77, 2, '2026-04-27 00:00:00'),
(500, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 32, 1, 0.79, 1, '2026-04-25 00:00:00'),
(501, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 33, 1, 0.81, 1, '2026-04-25 00:00:00'),
(502, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 34, 1, 0.74, 1, '2026-04-27 00:00:00'),
(503, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 35, 1, 0.78, 1, '2026-04-27 00:00:00'),
(504, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 36, 1, 0.82, 1, '2026-04-27 00:00:00'),
(505, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 37, 1, 0.7, 1, '2026-04-29 00:00:00'),
(506, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 38, 1, 0.75, 1, '2026-04-29 00:00:00'),
(507, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 39, 1, 0.72, 2, '2026-05-01 00:00:00'),
(508, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 40, 1, 0.78, 1, '2026-05-01 00:00:00'),
(509, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 41, 1, 0.73, 1, '2026-05-01 00:00:00'),
(510, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 42, 1, 0.76, 1, '2026-05-03 00:00:00'),
(511, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 43, 1, 0.71, 1, '2026-05-03 00:00:00'),
(512, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 44, 1, 0.8, 1, '2026-05-03 00:00:00'),
(513, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 45, 1, 0.84, 1, '2026-05-03 00:00:00'),
(514, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 46, 1, 0.75, 2, '2026-05-07 00:00:00'),
(515, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 47, 1, 0.72, 1, '2026-05-05 00:00:00'),
(516, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 48, 1, 0.78, 1, '2026-05-05 00:00:00'),
(517, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 49, 1, 0.8, 1, '2026-05-07 00:00:00'),
(518, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 50, 1, 0.73, 1, '2026-05-07 00:00:00'),
(519, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 51, 1, 0.77, 1, '2026-05-09 00:00:00'),
(520, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 52, 1, 0.82, 1, '2026-05-09 00:00:00'),
(521, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 53, 1, 0.79, 1, '2026-05-09 00:00:00'),
(522, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 54, 1, 0.85, 1, '2026-05-09 00:00:00'),
(523, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 55, 1, 0.72, 1, '2026-05-15 00:00:00'),
(524, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 56, 1, 0.76, 2, '2026-05-16 00:00:00'),
(525, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 57, 1, 0.75, 1, '2026-05-15 00:00:00'),
(526, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 58, 1, 0.79, 1, '2026-05-16 00:00:00'),
(527, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 59, 1, 0.73, 1, '2026-05-16 00:00:00'),
(528, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 60, 1, 0.77, 1, '2026-05-17 00:00:00'),
(529, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 61, 1, 0.81, 1, '2026-05-17 00:00:00'),
(530, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 62, 1, 0.74, 1, '2026-05-17 00:00:00'),
(531, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 63, 1, 0.83, 1, '2026-05-17 00:00:00'),
(532, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 64, 1, 0.7, 1, '2026-05-18 00:00:00'),
(533, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 65, 1, 0.76, 1, '2026-05-18 00:00:00'),
(534, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 66, 1, 0.72, 1, '2026-05-18 00:00:00'),
(535, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 67, 1, 0.78, 1, '2026-05-19 00:00:00'),
(536, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 68, 1, 0.75, 1, '2026-05-19 00:00:00'),
(537, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 69, 1, 0.8, 1, '2026-05-19 00:00:00'),
(538, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 70, 1, 0.74, 1, '2026-05-20 00:00:00'),
(539, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 71, 1, 0.77, 1, '2026-05-20 00:00:00'),
(540, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 72, 1, 0.82, 1, '2026-05-20 00:00:00'),
(541, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 73, 1, 0.71, 1, '2026-05-21 00:00:00'),
(542, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 74, 1, 0.79, 1, '2026-05-21 00:00:00'),
(543, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 75, 1, 0.76, 1, '2026-05-21 00:00:00'),
(544, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 76, 1, 0.83, 1, '2026-05-22 00:00:00'),
(545, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 77, 1, 0.78, 1, '2026-05-22 00:00:00'),
(546, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 78, 1, 0.75, 1, '2026-05-22 00:00:00'),
(547, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 79, 1, 0.8, 1, '2026-05-23 00:00:00'),
(548, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 80, 1, 0.74, 1, '2026-05-23 00:00:00'),
(549, 'i3cVAdwywoaTWD4U78SnMeJ3fBC2', 81, 1, 0.87, 1, '2026-05-23 00:00:00');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `user_lesson_progress`
--
ALTER TABLE `user_lesson_progress`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_user_lesson` (`firebase_uid`,`lesson_id`),
  ADD KEY `lesson_id` (`lesson_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `user_lesson_progress`
--
ALTER TABLE `user_lesson_progress`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=550;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `user_lesson_progress`
--
ALTER TABLE `user_lesson_progress`
  ADD CONSTRAINT `user_lesson_progress_ibfk_1` FOREIGN KEY (`lesson_id`) REFERENCES `vowel_lessons` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
